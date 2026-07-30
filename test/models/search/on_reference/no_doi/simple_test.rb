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

# Search::Reference::FieldRule's "no-doi:" directive
# (app/models/search/reference/field_rule.rb) finds references with no DOI
# recorded. It takes no argument - there isn't one to give - so using it
# alone, with nothing after the colon, must not raise.
#
# The reference search defaults to a LIMIT 100, ordered by citation
# (Search::ParsedRequest::DEFAULT_LIST_LIMIT/DEFAULT_ORDER_COLUMNS), so a
# bare "no-doi:" search can't reliably be checked for one specific
# fixture's inclusion/exclusion - which fixtures make the top 100
# alphabetically depends on how much other reference data exists, which
# can differ between environments (this broke in CI while passing
# locally). Combining "no-doi:" with "id:" scopes each check down to a
# single candidate reference, so the LIMIT/order never comes into play.
class SearchOnReferenceNoDoiSimpleTest < ActiveSupport::TestCase
  test "using the directive with no argument does not raise" do
    assert_kind_of ActiveRecord::Relation, run_search("no-doi:")
  end

  test "every result actually has no doi recorded" do
    results = run_search("no-doi:")
    assert !results.empty?, "Results expected."
    results.each do |reference|
      assert reference.doi.blank?,
             "#{reference.citation} should have no doi recorded"
    end
  end

  test "includes a reference with no doi recorded" do
    reference = references(:ref_type_is_book)
    results = run_search("id: #{reference.id} no-doi:")
    assert_includes results.map(&:id), reference.id
  end

  test "excludes a reference that has a doi recorded" do
    reference = references(:stanley_and_ross_1986_flora_of_se_qld)
    results = run_search("id: #{reference.id} no-doi:")
    assert_not_includes results.map(&:id), reference.id
  end

  def run_search(query_string)
    params = ActiveSupport::HashWithIndifferentAccess.new(
      query_target: "reference",
      query_string: query_string,
      current_user: build_edit_user
    )
    Search::Base.new(params).executed_query.results
  end
end
