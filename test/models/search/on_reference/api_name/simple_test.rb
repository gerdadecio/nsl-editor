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

# Search model tests for the api-name: / has-api-name: / has-no-api-name:
# reference search directives.
class SearchOnReferenceApiNameSimpleTest < ActiveSupport::TestCase
  # There are more reference fixtures than the default result limit, so
  # searches that match most of them need an explicit limit to be
  # deterministic.
  ALL = "limit: 500"

  setup do
    references(:paper_by_brassard).update_columns(api_name: "JIRA-Sync")
    references(:book_by_brassard).update_columns(api_name: "batch-loader")
    references(:journal_with_papers).update_columns(api_name: nil)
  end

  def search_ids(query_string)
    params = ActiveSupport::HashWithIndifferentAccess.new(
      query_target: "reference",
      query_string: query_string,
      current_user: build_edit_user
    )
    search = Search::Base.new(params)
    search.executed_query.results.collect(&:id)
  end

  test "api-name: matches the reference changed by that api" do
    assert_includes search_ids("api-name: jira-sync"),
                    references(:paper_by_brassard).id,
                    "Expected the reference changed by jira-sync in the results"
  end

  test "api-name: excludes a reference changed by another api" do
    refute_includes search_ids("api-name: jira-sync"),
                    references(:book_by_brassard).id,
                    "Expected the reference changed by batch-loader to be excluded"
  end

  test "api-name: ignores case" do
    assert_includes search_ids("api-name: JIRA-SYNC"),
                    references(:paper_by_brassard).id,
                    "Expected the search to be case insensitive"
  end

  test "api-name: adds wildcards at both ends" do
    assert_includes search_ids("api-name: sync"),
                    references(:paper_by_brassard).id,
                    "Expected a partial search term to match"
    assert_includes search_ids("api-name: loader"),
                    references(:book_by_brassard).id,
                    "Expected a partial search term to match"
  end

  test "api-name: excludes a reference never changed by an api" do
    refute_includes search_ids("api-name: sync"),
                    references(:journal_with_papers).id,
                    "Expected a reference with no api_name to be excluded"
  end

  test "has-api-name: includes a reference changed by an api" do
    ids = search_ids("has-api-name: #{ALL}")
    assert_includes ids, references(:paper_by_brassard).id,
                    "Expected the reference changed by jira-sync in the results"
    assert_includes ids, references(:book_by_brassard).id,
                    "Expected the reference changed by batch-loader in the results"
  end

  test "has-api-name: excludes a reference never changed by an api" do
    refute_includes search_ids("has-api-name: #{ALL}"),
                    references(:journal_with_papers).id,
                    "Expected a reference with no api_name to be excluded"
  end

  test "has-no-api-name: includes a reference never changed by an api" do
    assert_includes search_ids("has-no-api-name: #{ALL}"),
                    references(:journal_with_papers).id,
                    "Expected a reference with no api_name in the results"
  end

  test "has-no-api-name: excludes a reference changed by an api" do
    refute_includes search_ids("has-no-api-name: #{ALL}"),
                    references(:paper_by_brassard).id,
                    "Expected the reference changed by jira-sync to be excluded"
  end

  test "the two directives return disjoint result sets" do
    with_api_name = search_ids("has-api-name: #{ALL}")
    without_api_name = search_ids("has-no-api-name: #{ALL}")
    assert_empty with_api_name & without_api_name,
                 "A reference cannot both have and not have an api name"
  end

  test "api-name: combines with a leading citation search term" do
    ids = search_ids("brassard api-name: jira-sync")
    assert_includes ids, references(:paper_by_brassard).id,
                    "Expected the citation term and the api name to combine"
    refute_includes ids, references(:book_by_brassard).id,
                    "Expected a brassard reference changed by another api to be excluded"
  end
end
