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

# Regression test for search/search_result_summary/_more_results_for_limited.html.erb.
#
# NOTES (limit/total redesign, follow-up): a single reference matched by
# id: always has total == 1, so it can only exercise the partial's
# "elsif" branch (total > @search.parsed_request.limit) - not the "if"
# branch (total > count + page_increment_size), which needs more matching
# references than count + 500 and so can't be reproduced with one fixture.
#
# What this DOES cover, deterministically: with limit:1, this reference's
# own 36 attached instance fixtures used to leak into that elsif
# comparison. The old code compared @search.executed_query.total against
# params[:limit].to_i - a raw URL param that's blank (so .to_i is 0)
# whenever limit: comes from the query text, which it always does here.
# That meant "1 > 0", true, so the old code showed a spurious
# "List all"-style link even though limit:1 already returned every
# matching reference (1 of 1) - the 36 instances never actually factored
# into *this* particular comparison (the link text used
# @search.executed_query.total, not .results.size), but the wrong
# right-hand side of the comparison did, and the fix corrects that
# comparison to use @search.parsed_request.limit instead.
class SearchRefsOnIdMoreResultsLinkNotShownWhenLimitMatchesTest < ActionController::TestCase
  tests SearchController

  test "no more-results link when limit: exactly matches the (single) reference total" do
    ref = references(:bucket_reference_for_default_instances)
    get(:search,
        params: { query_target: "reference",
                  query_string: "id: #{ref.id} show-instances: limit:1" },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: [] })
    assert_response :success
    assert_select "#search-results-summary", /1 record\b/,
                  "Should find 1 record"
    # NOTES (test fix): the wrapping span itself
    # (#search-results-limited-notice) always renders whenever
    # total >= limit - which, with Search::OnModel::ListQuery#limited
    # hardcoded true, is nearly always the case - regardless of whether
    # the partial inside it actually produces a link. What this test
    # protects is the absence of the link itself, not the (harmless,
    # empty) wrapping span.
    assert_select "#search-results-limited-notice a", false,
                  "No 'List more'/'List all' link should appear when the " \
                  "limit already covers every matching reference, however " \
                  "many instances that reference has attached"
  end
end
