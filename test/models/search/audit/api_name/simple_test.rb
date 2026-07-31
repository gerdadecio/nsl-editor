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

# Search model tests for the api-name: activity (audit) search directive.
class SearchAuditApiNameSimpleTest < ActiveSupport::TestCase
  setup do
    names(:a_family).update_columns(api_name: "JIRA-Sync",
      api_at: Time.utc(2026, 7, 27, 12))
    references(:paper_by_brassard)
      .update_columns(api_name: "batch-loader",
        api_at: Time.utc(2026, 8, 15, 12))
    authors(:brassard).update_columns(api_name: nil, api_at: nil)
  end

  def build_qa_user
    qa_user = SessionUser.new
    qa_user.username = "qa-tester"
    qa_user.full_name = "a QA tester"
    qa_user.groups = ["QA"]
    qa_user
  end

  def search_keys(query_string)
    params = ActiveSupport::HashWithIndifferentAccess.new(
      query_target: "activity",
      query_string: query_string,
      current_user: build_qa_user
    )
    search = Search::Base.new(params)
    search.executed_query.results.collect { |r| "#{r.class.base_class.name}##{r.id}" }
  end

  test "api-name: matches a name record changed by that api" do
    assert_includes search_keys("api-name: jira-sync"),
      "Name##{names(:a_family).id}",
      "Expected the name changed by JIRA-Sync in the results"
  end

  test "api-name: is case-insensitive" do
    assert_includes search_keys("api-name: JIRA-SYNC"),
      "Name##{names(:a_family).id}",
      "Expected a different-case search to match"
  end

  test "api-name: excludes records changed by another api" do
    refute_includes search_keys("api-name: jira-sync"),
      "Reference##{references(:paper_by_brassard).id}",
      "Expected the reference changed by batch-loader to be excluded"
  end

  test "api-name: supports wildcards" do
    keys = search_keys("api-name: *loader*")
    assert_includes keys,
      "Reference##{references(:paper_by_brassard).id}",
      "Expected a wildcard search to match batch-loader"
    refute_includes keys,
      "Name##{names(:a_family).id}",
      "Expected a *loader* search to exclude JIRA-Sync"
  end

  test "api-name: matches records across record types" do
    keys = search_keys("api-name: *")
    assert_includes keys,
      "Name##{names(:a_family).id}",
      "Expected the api-changed name in the results"
    assert_includes keys,
      "Reference##{references(:paper_by_brassard).id}",
      "Expected the api-changed reference in the results"
  end

  test "api-name: excludes records never changed by an api" do
    refute_includes search_keys("api-name: *"),
      "Author##{authors(:brassard).id}",
      "Expected an author with no api_name to be excluded"
  end

  test "api-name: combines with api-recorded-after:" do
    keys = search_keys("api-name: *loader* api-recorded-after: 2026-08-01")
    assert_includes keys,
      "Reference##{references(:paper_by_brassard).id}",
      "Expected the batch-loader reference api-changed in August to match"
    refute_includes keys,
      "Name##{names(:a_family).id}",
      "Expected the JIRA-Sync name to be excluded by both criteria"
  end

  test "api-name: without a value stops with an error" do
    error = assert_raises(RuntimeError) { search_keys("api-name:") }
    assert_match(/api-name: needs a value/, error.message)
  end
end
