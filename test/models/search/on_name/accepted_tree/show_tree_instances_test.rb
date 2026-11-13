# frozen_string_literal: true

#   Copyright 2026 Australian National Botanic Gardens
#   This file is part of the NSL Editor.
#   Licensed under the Apache License, Version 2.0

require "test_helper"
load "test/models/search/users.rb"
load "test/models/search/on_name/test_helper.rb"

# NSL-6048: show-tree-instances: shows each name with only the instance
# used for it in the current version of the accepted tree, plus synonymy.
class SearchOnNameAcceptedTreeShowTreeInstancesTest < ActiveSupport::TestCase
  setup do
    @name = names(:casuarina_inophloia)
    @tree_instance = instances(:casuarina_inophloia_by_mueller_and_bailey)
  end

  def results_for(query_string)
    search = Search::Base.new(ActiveSupport::HashWithIndifferentAccess.new(
      query_target: "name",
      query_string: query_string,
      current_user: build_edit_user,
    ))
    search.executed_query.results
  end

  def instance_ids(results)
    results.select { |rec| rec.is_a?(Instance) }.map(&:id)
  end

  test "show-instances: shows all the name's instances" do
    results = results_for("id: #{@name.id} show-instances:")
    assert_equal 4, instance_ids(results).size
  end

  test "show-tree-instances: shows only the accepted tree instance" do
    results = results_for("id: #{@name.id} show-tree-instances:")
    confirm_results_class(results)
    assert_equal @name, results.first
    assert_equal [ @tree_instance.id ], instance_ids(results)
  end

  test "sti: is short for show-tree-instances:" do
    results = results_for("id: #{@name.id} sti:")
    assert_equal [ @tree_instance.id ], instance_ids(results)
  end

  test "show-tree-instances: wins over show-instances:" do
    results = results_for("id: #{@name.id} show-instances: show-tree-instances:")
    assert_equal [ @tree_instance.id ], instance_ids(results)
  end

  test "the tree instance's synonymy is shown" do
    synonym = instances(:metrosideros_costata_is_basionym_of_angophora_costata).dup
    synonym.cited_by_id = @tree_instance.id
    synonym.reference_id = @tree_instance.reference_id
    synonym.save!(validate: false)

    results = results_for("id: #{@name.id} show-tree-instances:")
    assert_equal [ @tree_instance.id, synonym.id ], instance_ids(results)
    assert_equal "instance-is-cited-by", results.last.display_as
  end

  test "a name that isn't on the accepted tree shows no instances" do
    name = names(:metrosideros_costata)
    assert Instance.exists?(name_id: name.id), "the name needs instances for this test"

    results = results_for("id: #{name.id} show-tree-instances:")
    assert_equal [ name ], results
  end

  test "an instance on a tree that isn't the accepted tree isn't shown" do
    # This tree element is on the FOA tree, for angophora_costata.
    foa_instance = instances(:invalid_publication_standalone_instance)
    name = names(:angophora_costata)

    results = results_for("id: #{name.id} show-tree-instances:")
    assert_not_includes instance_ids(results), foa_instance.id
  end

  test "show-tree-instances: isn't allowed for other searches" do
    parsed = Search::ParsedRequest.new(ActiveSupport::HashWithIndifferentAccess.new(
      canonical_query_target: "names",
      query_string: "casuarina sti:",
      current_user: build_edit_user,
    ))
    assert parsed.show_tree_instances

    error = assert_raises(RuntimeError) do
      Search::ParsedRequest.new(ActiveSupport::HashWithIndifferentAccess.new(
        canonical_query_target: "references",
        query_string: "casuarina show-tree-instances:",
        current_user: build_edit_user,
      ))
    end
    assert_match(/only supported for Name searches/, error.message)
  end
end
