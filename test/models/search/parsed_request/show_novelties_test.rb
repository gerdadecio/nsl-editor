# frozen_string_literal: true

#   Copyright 2015 Australian National Botanic Gardens
#
#   This file is part of the NSL Editor.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
require "test_helper"
load "test/models/search/users.rb"

# Tests for show-novelties: parsing in Search::ParsedRequest.
class SearchParsedRequestShowNoveltiesTest < ActiveSupport::TestCase
  def ref_params(query_string)
    ActiveSupport::HashWithIndifferentAccess.new(
      query_target: "reference",
      canonical_query_target: "references",
      query_string: query_string,
      include_common_and_cultivar_session: true,
      current_user: build_edit_user
    )
  end

  test "show-novelties: sets show_novelties true and order_novelties_by_page false" do
    pr = Search::ParsedRequest.new(ref_params("show-novelties:"))
    assert pr.show_novelties, "show_novelties should be true"
    assert_not pr.order_novelties_by_page, "order_novelties_by_page should be false"
  end

  test "show-novelties-by-page: sets show_novelties true and order_novelties_by_page true" do
    pr = Search::ParsedRequest.new(ref_params("show-novelties-by-page:"))
    assert pr.show_novelties, "show_novelties should be true"
    assert pr.order_novelties_by_page, "order_novelties_by_page should be true"
  end

  test "no novelties directive sets show_novelties false" do
    pr = Search::ParsedRequest.new(ref_params(""))
    assert_not pr.show_novelties, "show_novelties should be false when directive absent"
  end

  test "nov: abbreviation expands to show-novelties:" do
    pr = Search::ParsedRequest.new(ref_params("nov:"))
    assert pr.show_novelties, "nov: should expand to show-novelties:"
    assert_not pr.order_novelties_by_page
  end

  test "snov: abbreviation expands to show-novelties:" do
    pr = Search::ParsedRequest.new(ref_params("snov:"))
    assert pr.show_novelties, "snov: should expand to show-novelties:"
  end

  test "s-nov: abbreviation expands to show-novelties:" do
    pr = Search::ParsedRequest.new(ref_params("s-nov:"))
    assert pr.show_novelties, "s-nov: should expand to show-novelties:"
  end

  test "novbp: abbreviation expands to show-novelties-by-page:" do
    pr = Search::ParsedRequest.new(ref_params("novbp:"))
    assert pr.show_novelties, "novbp: should expand to show-novelties-by-page:"
    assert pr.order_novelties_by_page, "novbp: should set order_novelties_by_page true"
  end

  test "show-novelties: raises error for non-reference targets" do
    params = ActiveSupport::HashWithIndifferentAccess.new(
      query_target: "name",
      canonical_query_target: "names",
      query_string: "show-novelties:",
      include_common_and_cultivar_session: true,
      current_user: build_edit_user
    )
    assert_raises(RuntimeError) { Search::ParsedRequest.new(params) }
  end
end
