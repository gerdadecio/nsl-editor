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

# Search model tests for the api-at: / api-at-after: / api-at-before:
# reference search directives.
class SearchOnReferenceApiAtSimpleTest < ActiveSupport::TestCase
  DISPLAY_ZONE = "Australia/Melbourne"

  setup do
    Time.use_zone(DISPLAY_ZONE) do
      references(:paper_by_brassard)
        .update_columns(api_at: Time.zone.parse("2026-07-27 09:00"))
      references(:book_by_brassard)
        .update_columns(api_at: Time.zone.parse("2026-08-15 12:00"))
      references(:journal_with_papers).update_columns(api_at: nil)
    end
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

  test "api-at: matches a reference changed on that date" do
    assert_includes search_ids("api-at: 27-07-2026"),
                    references(:paper_by_brassard).id,
                    "Expected the reference changed on 27-07-2026 in the results"
  end

  test "api-at: excludes a reference changed on another date" do
    refute_includes search_ids("api-at: 27-07-2026"),
                    references(:book_by_brassard).id,
                    "Expected the reference changed on 15-08-2026 to be excluded"
  end

  test "api-at: uses the display timezone, not UTC" do
    refute_includes search_ids("api-at: 26-07-2026"),
                    references(:paper_by_brassard).id,
                    "9am on the 27th in #{DISPLAY_ZONE} must not match the 26th"
  end

  test "api-at: matches on month and year alone" do
    assert_includes search_ids("api-at: 07-2026"),
                    references(:paper_by_brassard).id,
                    "Expected a month-and-year search to match"
    refute_includes search_ids("api-at: 07-2026"),
                    references(:book_by_brassard).id,
                    "Expected a reference changed in August to be excluded"
  end

  test "api-at: matches on year alone" do
    ids = search_ids("api-at: 2026")
    assert_includes ids, references(:paper_by_brassard).id,
                    "Expected a year search to match the July reference"
    assert_includes ids, references(:book_by_brassard).id,
                    "Expected a year search to match the August reference"
  end

  test "api-at: excludes references that have never been changed by the api" do
    refute_includes search_ids("api-at: 2026"),
                    references(:journal_with_papers).id,
                    "Expected a reference with no api_at to be excluded"
  end

  test "api-at: does not match against the publication date" do
    refute_includes search_ids("api-at: 1987"),
                    references(:paper_by_brassard).id,
                    "api-at: must search api_at, not the publication date"
  end

  test "api-at-after: excludes the named day itself" do
    refute_includes search_ids("api-at-after: 27-07-2026"),
                    references(:paper_by_brassard).id,
                    "Expected after: to exclude references changed on that same day"
  end

  test "api-at-after: includes a reference changed on a later day" do
    ids = search_ids("api-at-after: 26-07-2026")
    assert_includes ids, references(:paper_by_brassard).id,
                    "Expected the 27th to be after the 26th"
    assert_includes ids, references(:book_by_brassard).id,
                    "Expected the 15th of August to be after the 26th of July"
  end

  test "api-at-before: excludes the named day itself" do
    refute_includes search_ids("api-at-before: 27-07-2026"),
                    references(:paper_by_brassard).id,
                    "Expected before: to exclude references changed on that same day"
  end

  test "api-at-before: includes a reference changed on an earlier day" do
    ids = search_ids("api-at-before: 28-07-2026")
    assert_includes ids, references(:paper_by_brassard).id,
                    "Expected the 27th to be before the 28th"
    refute_includes ids, references(:book_by_brassard).id,
                    "Expected the 15th of August to be excluded"
  end

  test "api-at-after: and api-at-before: combine into a date range" do
    ids = search_ids("api-at-after: 26-07-2026 api-at-before: 28-07-2026")
    assert_includes ids, references(:paper_by_brassard).id,
                    "Expected the 27th to fall inside the range"
    refute_includes ids, references(:book_by_brassard).id,
                    "Expected the 15th of August to fall outside the range"
  end
end
