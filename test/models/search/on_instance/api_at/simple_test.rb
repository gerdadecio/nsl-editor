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
# instance search directives.
class SearchOnInstanceApiAtSimpleTest < ActiveSupport::TestCase
  DISPLAY_ZONE = "Australia/Melbourne"

  setup do
    Time.use_zone(DISPLAY_ZONE) do
      instances(:gaertner_created_metrosideros_costata)
        .update_columns(api_at: Time.zone.parse("2026-07-27 09:00"))
      instances(:britten_created_angophora_costata)
        .update_columns(api_at: Time.zone.parse("2026-08-15 12:00"))
      instances(:triodia_in_brassard).update_columns(api_at: nil)
    end
  end

  def search_ids(query_string)
    params = ActiveSupport::HashWithIndifferentAccess.new(
      query_target: "instance",
      query_string: query_string,
      current_user: build_edit_user
    )
    search = Search::Base.new(params)
    search.executed_query.results.collect(&:id)
  end

  test "api-at: matches an instance changed on that date" do
    assert_includes search_ids("api-at: 27-07-2026"),
                    instances(:gaertner_created_metrosideros_costata).id,
                    "Expected the instance changed on 27-07-2026 in the results"
  end

  test "api-at: excludes an instance changed on another date" do
    refute_includes search_ids("api-at: 27-07-2026"),
                    instances(:britten_created_angophora_costata).id,
                    "Expected the instance changed on 15-08-2026 to be excluded"
  end

  test "api-at: uses the display timezone, not UTC" do
    refute_includes search_ids("api-at: 26-07-2026"),
                    instances(:gaertner_created_metrosideros_costata).id,
                    "9am on the 27th in #{DISPLAY_ZONE} must not match the 26th"
  end

  test "api-at: matches on month and year alone" do
    assert_includes search_ids("api-at: 07-2026"),
                    instances(:gaertner_created_metrosideros_costata).id,
                    "Expected a month-and-year search to match"
    refute_includes search_ids("api-at: 07-2026"),
                    instances(:britten_created_angophora_costata).id,
                    "Expected an instance changed in August to be excluded"
  end

  test "api-at: matches on year alone" do
    ids = search_ids("api-at: 2026")
    assert_includes ids, instances(:gaertner_created_metrosideros_costata).id,
                    "Expected a year search to match the July instance"
    assert_includes ids, instances(:britten_created_angophora_costata).id,
                    "Expected a year search to match the August instance"
  end

  test "api-at: excludes instances that have never been changed by the api" do
    refute_includes search_ids("api-at: 2026"),
                    instances(:triodia_in_brassard).id,
                    "Expected an instance with no api_at to be excluded"
  end

  test "api-at-after: excludes the named day itself" do
    refute_includes search_ids("api-at-after: 27-07-2026"),
                    instances(:gaertner_created_metrosideros_costata).id,
                    "Expected after: to exclude instances changed on that same day"
  end

  test "api-at-after: includes an instance changed on a later day" do
    ids = search_ids("api-at-after: 26-07-2026")
    assert_includes ids, instances(:gaertner_created_metrosideros_costata).id,
                    "Expected the 27th to be after the 26th"
    assert_includes ids, instances(:britten_created_angophora_costata).id,
                    "Expected the 15th of August to be after the 26th of July"
  end

  test "api-at-before: excludes the named day itself" do
    refute_includes search_ids("api-at-before: 27-07-2026"),
                    instances(:gaertner_created_metrosideros_costata).id,
                    "Expected before: to exclude instances changed on that same day"
  end

  test "api-at-before: includes an instance changed on an earlier day" do
    ids = search_ids("api-at-before: 28-07-2026")
    assert_includes ids, instances(:gaertner_created_metrosideros_costata).id,
                    "Expected the 27th to be before the 28th"
    refute_includes ids, instances(:britten_created_angophora_costata).id,
                    "Expected the 15th of August to be excluded"
  end

  test "api-at-after: and api-at-before: combine into a date range" do
    ids = search_ids("api-at-after: 26-07-2026 api-at-before: 28-07-2026")
    assert_includes ids, instances(:gaertner_created_metrosideros_costata).id,
                    "Expected the 27th to fall inside the range"
    refute_includes ids, instances(:britten_created_angophora_costata).id,
                    "Expected the 15th of August to fall outside the range"
  end
end
