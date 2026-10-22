# frozen_string_literal: true

#   Copyright 2015 Australian National Botanic Gardens
#   This file is part of the NSL Editor.
#   Licensed under the Apache License, Version 2.0

require "test_helper"
load "test/models/search/users.rb"

# NSL-6001: instance-limit: parsing in Search::ParsedRequest.
class SearchParsedRequestInstanceLimitTest < ActiveSupport::TestCase
  def ref_params(query_string)
    ActiveSupport::HashWithIndifferentAccess.new(
      query_target: "reference",
      canonical_query_target: "references",
      query_string: query_string,
      include_common_and_cultivar_session: true,
      current_user: build_edit_user
    )
  end

  test "instance limit defaults to 1000" do
    pr = Search::ParsedRequest.new(ref_params("show-instances:"))
    assert_equal 1000, pr.instance_limit
  end

  test "instance-limit: sets the instance limit and leaves limit at its default" do
    pr = Search::ParsedRequest.new(ref_params("show-instances: instance-limit: 50"))
    assert_equal 50, pr.instance_limit
    assert_equal Search::ParsedRequest::DEFAULT_LIST_LIMIT, pr.limit,
                 "limit: must not pick up the number from instance-limit:"
  end

  test "instance-limit: and limit: are parsed separately in either order" do
    [ "limit: 7 show-instances: instance-limit: 50",
      "instance-limit: 50 show-instances: limit: 7" ].each do |query|
      pr = Search::ParsedRequest.new(ref_params(query))
      assert_equal 50, pr.instance_limit, query
      assert_equal 7, pr.limit, query
    end
  end

  test "instance-limit: without a space after the colon is accepted" do
    pr = Search::ParsedRequest.new(ref_params("show-instances: instance-limit:25"))
    assert_equal 25, pr.instance_limit
  end

  test "instance-limit: is removed from the where arguments" do
    pr = Search::ParsedRequest.new(ref_params("nuytsia show-instances: instance-limit: 50"))
    assert_no_match(/instance-limit|50/, pr.where_arguments)
  end

  test "instance-limit: 0 is rejected" do
    error = assert_raises(RuntimeError) do
      Search::ParsedRequest.new(ref_params("show-instances: instance-limit: 0"))
    end
    assert_match(/Invalid instance limit: 0/, error.message)
  end

  test "a non-numeric instance-limit: is rejected" do
    error = assert_raises(RuntimeError) do
      Search::ParsedRequest.new(ref_params("show-instances: instance-limit: lots"))
    end
    assert_match(/Invalid instance limit: lots/, error.message)
  end
end
