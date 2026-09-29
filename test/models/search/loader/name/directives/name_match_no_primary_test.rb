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

# Search::Loader::Name::FieldRule's "name-match-no-primary:" directive
# (app/models/search/loader/name/field_rule.rb) finds loader names that:
#   - match exactly one existing NSL name by simple_name,
#   - that name has no primary instance, and
#   - the loader name doesn't already have a recorded loader_name_match.
#
# It takes no argument (jira 5603/similar - the rule previously had no
# takes_no_arg: true, so using it as documented, with no value after the
# colon, raised "name-match-no-primary: directive needs an argument").
class SearchLoaderNameDirectivesNameMatchNoPrimaryTest < ActiveSupport::TestCase
  setup do
    params = ActiveSupport::HashWithIndifferentAccess.new(
      query_target: "loader_names",
      query_string: "name-match-no-primary: any-batch:",
      current_user: build_edit_user
    )
    search = Search::Base.new(params)
    @ids = search.executed_query.results.map(&:id)
  end

  test "includes a loader name with exactly one matching name and no primary instance" do
    assert_includes @ids, loader_names(:no_primary_no_match_candidate).id
  end

  test "excludes a loader name whose matching name has a primary instance" do
    assert_not_includes @ids, loader_names(:has_primary_instance_candidate).id
  end

  test "excludes a loader name that already has a recorded match" do
    assert_not_includes @ids, loader_names(:already_matched_candidate).id
  end

  test "excludes a loader name matching more than one name" do
    assert_not_includes @ids, loader_names(:multiple_name_matches_candidate).id
  end

  test "using the directive with no argument does not raise" do
    assert_kind_of Array, @ids
  end
end
