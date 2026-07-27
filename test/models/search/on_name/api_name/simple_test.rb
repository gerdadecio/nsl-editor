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

class SearchOnNameApiNameSimpleTest < ActiveSupport::TestCase
  # There are more name fixtures than the default result limit, so searches
  # that match most of them need an explicit limit to be deterministic.
  ALL = "limit: 500"

  setup do
    names(:the_regnum).update_columns(api_name: "JIRA-Sync")
    names(:a_family).update_columns(api_name: "batch-loader")
    names(:a_species).update_columns(api_name: nil)
  end

  def search_ids(query_string)
    params = ActiveSupport::HashWithIndifferentAccess.new(
      query_target: "name",
      query_string: query_string,
      current_user: build_edit_user
    )
    search = Search::Base.new(params)
    confirm_results_class(search.executed_query.results)
    search.executed_query.results.collect(&:id)
  end

  test "api-name: matches the name changed by that api" do
    assert_includes search_ids("api-name: jira-sync"),
                    names(:the_regnum).id,
                    "Expected the name changed by jira-sync in the results"
  end

  test "api-name: excludes a name changed by another api" do
    refute_includes search_ids("api-name: jira-sync"),
                    names(:a_family).id,
                    "Expected the name changed by batch-loader to be excluded"
  end

  test "api-name: ignores case" do
    assert_includes search_ids("api-name: JIRA-SYNC"),
                    names(:the_regnum).id,
                    "Expected the search to be case insensitive"
  end

  test "api-name: adds wildcards at both ends" do
    assert_includes search_ids("api-name: sync"),
                    names(:the_regnum).id,
                    "Expected a partial search term to match"
    assert_includes search_ids("api-name: loader"),
                    names(:a_family).id,
                    "Expected a partial search term to match"
  end

  test "api-name: excludes a name never changed by an api" do
    refute_includes search_ids("api-name: sync"),
                    names(:a_species).id,
                    "Expected a name with no api_name to be excluded"
  end

  test "has-api-name: includes a name changed by an api" do
    ids = search_ids("has-api-name: #{ALL}")
    assert_includes ids, names(:the_regnum).id,
                    "Expected the name changed by jira-sync in the results"
    assert_includes ids, names(:a_family).id,
                    "Expected the name changed by batch-loader in the results"
  end

  test "has-api-name: excludes a name never changed by an api" do
    refute_includes search_ids("has-api-name: #{ALL}"),
                    names(:a_species).id,
                    "Expected a name with no api_name to be excluded"
  end

  test "has-no-api-name: includes a name never changed by an api" do
    assert_includes search_ids("has-no-api-name: #{ALL}"),
                    names(:a_species).id,
                    "Expected a name with no api_name in the results"
  end

  test "has-no-api-name: excludes a name changed by an api" do
    refute_includes search_ids("has-no-api-name: #{ALL}"),
                    names(:the_regnum).id,
                    "Expected the name changed by jira-sync to be excluded"
  end

  test "the two directives return disjoint result sets" do
    with_api_name = search_ids("has-api-name: #{ALL}")
    without_api_name = search_ids("has-no-api-name: #{ALL}")
    assert_empty with_api_name & without_api_name,
                 "A name cannot both have and not have an api name"
  end
end
