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

# Search model tests for the api-recorded-at: / api-recorded-since: /
# api-recorded-after: / api-recorded-before: / date-api-recorded:
# activity (audit) search directives.
class SearchAuditApiAtSimpleTest < ActiveSupport::TestCase
  setup do
    names(:a_family).update_columns(api_name: "JIRA-Sync",
      api_at: Time.utc(2026, 7, 27, 12))
    references(:paper_by_brassard)
      .update_columns(api_name: "JIRA-Sync",
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

  test "api-recorded-at: matches a record changed on that date" do
    assert_includes search_keys("api-recorded-at: 2026-07-27"),
      "Name##{names(:a_family).id}",
      "Expected the name api-changed on 27-07-2026 in the results"
  end

  test "api-recorded-at: excludes a record changed on another date" do
    refute_includes search_keys("api-recorded-at: 2026-07-27"),
      "Reference##{references(:paper_by_brassard).id}",
      "Expected the reference api-changed on 15-08-2026 to be excluded"
  end

  test "api-recorded-at: excludes records never changed by an api" do
    refute_includes search_keys("api-recorded-at: 2026-07-27"),
      "Author##{authors(:brassard).id}",
      "Expected an author with no api_at to be excluded"
  end

  test "api-recorded-since: matches records changed on or after the date" do
    keys = search_keys("api-recorded-since: 2026-07-27")
    assert_includes keys,
      "Name##{names(:a_family).id}",
      "Expected a record api-changed on the boundary date to match"
    assert_includes keys,
      "Reference##{references(:paper_by_brassard).id}",
      "Expected a record api-changed after the date to match"
  end

  test "api-recorded-since: excludes records changed before the date" do
    refute_includes search_keys("api-recorded-since: 2026-08-01"),
      "Name##{names(:a_family).id}",
      "Expected a record api-changed in July to be excluded"
  end

  test "api-recorded-after: matches records changed on or after the date" do
    keys = search_keys("api-recorded-after: 2026-08-01")
    assert_includes keys,
      "Reference##{references(:paper_by_brassard).id}",
      "Expected a record api-changed after the date to match"
    refute_includes keys,
      "Name##{names(:a_family).id}",
      "Expected a record api-changed before the date to be excluded"
  end

  test "api-recorded-before: matches records changed before the date only" do
    keys = search_keys("api-recorded-before: 2026-08-01")
    assert_includes keys,
      "Name##{names(:a_family).id}",
      "Expected a record api-changed in July to match"
    refute_includes keys,
      "Reference##{references(:paper_by_brassard).id}",
      "Expected a record api-changed in August to be excluded"
  end

  test "api-recorded-before: excludes records changed on the date itself" do
    refute_includes search_keys("api-recorded-before: 2026-07-27"),
      "Name##{names(:a_family).id}",
      "Expected the boundary date itself to be excluded"
  end

  test "date-api-recorded: matches records changed on that day" do
    keys = search_keys("date-api-recorded: 2026-07-27")
    assert_includes keys,
      "Name##{names(:a_family).id}",
      "Expected the name api-changed on 27-07-2026 in the results"
    refute_includes keys,
      "Reference##{references(:paper_by_brassard).id}",
      "Expected the reference api-changed on 15-08-2026 to be excluded"
  end

  test "api-recorded-at: without a value stops with an error" do
    error = assert_raises(RuntimeError) { search_keys("api-recorded-at:") }
    assert_match(/api-recorded-at: needs a value/, error.message)
  end
end
