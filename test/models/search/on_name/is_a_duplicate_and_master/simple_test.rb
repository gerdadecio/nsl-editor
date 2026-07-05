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
load "test/models/search/on_name/test_helper.rb"

# Search for names that are both a duplicate of another name AND themselves
# have duplicates pointing at them (i.e. they sit in the middle of a
# duplicate chain).
#
# Fixture chain used:
#   a_duplicate_of_a_duplicate_species -> a_duplicate_species -> a_species
#
# a_duplicate_species satisfies both conditions:
#   - duplicate_of_id is not null  (points to a_species)
#   - id appears in duplicate_of_id of another name  (a_duplicate_of_a_duplicate_species)
class SearchOnNameIsADuplicateAndMasterSimpleTest < ActiveSupport::TestCase
  test "is-a-duplicate-and-master: returns results" do
    params = ActiveSupport::HashWithIndifferentAccess.new(
      query_target: "name",
      query_string: "is-a-duplicate-and-master:",
      current_user: build_edit_user
    )
    search = Search::Base.new(params)
    confirm_results_class(search.executed_query.results)
    assert !search.executed_query.results.empty?,
           "Expected at least one name that is both a duplicate and a master"
  end

  test "is-a-duplicate-and-master: includes a_duplicate_species in results" do
    params = ActiveSupport::HashWithIndifferentAccess.new(
      query_target: "name",
      query_string: "is-a-duplicate-and-master:",
      current_user: build_edit_user
    )
    search = Search::Base.new(params)
    result_ids = search.executed_query.results.map(&:id)
    assert_includes result_ids,
                    names(:a_duplicate_species).id,
                    "Expected a_duplicate_species (duplicate of a_species, master of a_duplicate_of_a_duplicate_species) to appear in results"
  end
end
