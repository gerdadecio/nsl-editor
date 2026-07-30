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

# Search::Loader::Name::FieldRule's "no-nomination:" directive
# (app/models/search/loader/name/field_rule.rb) finds loader names that:
#   - are an accepted or excluded record (not e.g. a synonym), and
#   - have a recorded loader_name_match that hasn't yet been nominated a
#     reference to use for the tree instance (no batch default reference
#     chosen, no copy-and-append from an existing use, and no standalone
#     instance chosen).
#
# It takes no argument (the directive doesn't have any arguments to give -
# the rule previously had no takes_no_arg: true, so using it as the user
# always does, with no value after the colon, raised "no-nomination:
# directive needs an argument").
class SearchLoaderNameDirectivesNoNominationTest < ActiveSupport::TestCase
  setup do
    params = ActiveSupport::HashWithIndifferentAccess.new(
      query_target: "loader_names",
      query_string: "no-nomination: any-batch:",
      current_user: build_edit_user
    )
    search = Search::Base.new(params)
    @ids = search.executed_query.results.map(&:id)
  end

  test "includes an accepted name with an unresolved match" do
    assert_includes @ids, loader_names(:zzz_test_parent_with_match).id
  end

  test "excludes a synonym with an otherwise-unresolved match" do
    assert_not_includes @ids, loader_names(:synonym_guards_pass).id
  end

  test "excludes an accepted name whose match already uses an existing instance" do
    assert_not_includes @ids, loader_names(:zzz_test_parent_using_existing).id
  end

  test "excludes an accepted name with no recorded match at all" do
    assert_not_includes @ids, loader_names(:no_primary_no_match_candidate).id
  end

  test "using the directive with no argument does not raise" do
    assert_kind_of Array, @ids
  end
end
