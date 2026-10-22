# frozen_string_literal: true

#   Copyright 2015 Australian National Botanic Gardens
#   This file is part of the NSL Editor.
#   Licensed under the Apache License, Version 2.0

require "test_helper"
load "test/models/search/users.rb"

# NSL-6001: reference searches cap the standalone instances shown per
# reference (instance-limit:), count instance rows separately, and add a
# notice after a reference whose instances were cut short.
class SearchOnReferenceInstanceLimitExpansionTest < ActiveSupport::TestCase
  NOTICE = Search::Reference::InstanceExpansion::NOTICE

  setup do
    @ref = references(:bucket_reference_for_default_instances)
    @standalone_count = Instance.where(reference_id: @ref.id, cited_by_id: nil).count
    assert_operator @standalone_count, :>, 3, "Fixture precondition: needs more than 3 standalone instances"
  end

  def search_for(reference, query_suffix)
    Search::Base.new(
      ActiveSupport::HashWithIndifferentAccess.new(
        query_target: "references",
        query_string: "id: #{reference.id} #{query_suffix}",
        current_user: build_edit_user
      )
    ).executed_query
  end

  def notices(results)
    results.select { |r| r.is_a?(Hash) && r[:display_as] == NOTICE }
  end

  def instance_rows(results)
    results.grep(Instance)
  end

  test "no notice when every instance fits within the default limit" do
    query = search_for(@ref, "show-instances:")
    assert_empty notices(query.results)
    assert_equal instance_rows(query.results).size, query.instance_row_count
  end

  test "instance-limit: caps standalone instances and adds a notice with a next link" do
    query = search_for(@ref, "show-instances: instance-limit: 3")
    standalone_shown = instance_rows(query.results).count { |i| i.display_as == :instance_within_reference }
    assert_equal 3, standalone_shown

    notice = notices(query.results).sole
    assert_equal @ref.id, notice[:reference_id]
    assert_equal 1, notice[:first]
    assert_equal 3, notice[:last]
    assert_equal @standalone_count, notice[:total]
    assert_equal instance_rows(query.results).size, notice[:row_count]
    assert_equal "id: #{@ref.id} show-instances: instance-offset: 3 instance-limit: 3",
                 notice[:next_query_string]
    assert_equal NOTICE, query.results.last[:display_as], "The notice should follow the reference's instances"
  end

  test "instance_row_count counts instance rows, not references or notices" do
    query = search_for(@ref, "show-instances: instance-limit: 3")
    assert_equal instance_rows(query.results).size, query.instance_row_count
    assert_equal 1, query.count, "The record count is still references only"
  end

  test "an offset alone gives a notice without a next link" do
    query = search_for(@ref, "show-instances: instance-offset: 2")
    notice = notices(query.results).sole
    assert_equal 3, notice[:first]
    assert_equal @standalone_count, notice[:last]
    assert_nil notice[:next_query_string]
  end

  test "the last window has no next link" do
    query = search_for(@ref, "show-instances: instance-offset: 3 instance-limit: #{@standalone_count}")
    notice = notices(query.results).sole
    assert_equal @standalone_count, notice[:last]
    assert_nil notice[:next_query_string]
  end

  test "an offset past the end shows no instances and says so" do
    query = search_for(@ref, "show-instances: instance-offset: #{@standalone_count + 5}")
    assert_empty instance_rows(query.results)
    notice = notices(query.results).sole
    assert_operator notice[:first], :>, notice[:last]
  end

  test "the next link keeps by-page ordering" do
    query = search_for(@ref, "show-instances-by-page: instance-limit: 3")
    assert_equal "id: #{@ref.id} show-instances-by-page: instance-offset: 3 instance-limit: 3",
                 notices(query.results).sole[:next_query_string]
  end

  test "novelties are capped the same way" do
    ref = references(:de_fructibus_et_seminibus_plantarum)
    primary_count = Instance.joins(:instance_type)
      .where(reference_id: ref.id, cited_by_id: nil, instance_type: { primary_instance: true }).count
    assert_operator primary_count, :>, 1, "Fixture precondition: needs more than 1 primary instance"

    query = search_for(ref, "show-novelties: instance-limit: 1")
    notice = notices(query.results).sole
    assert_equal 1, notice[:last]
    assert_equal primary_count, notice[:total]
    assert_equal "id: #{ref.id} show-novelties: instance-offset: 1 instance-limit: 1",
                 notice[:next_query_string]
    assert_equal instance_rows(query.results).size, query.instance_row_count
  end
end
