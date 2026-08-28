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

# Regression test for the user-tester report: with a default batch set in
# the session, the "Loader names (any batch)" target was still being
# restricted to that default batch - "default-batch:" and "any-batch:" were
# both being appended to the query string and AND-ed together, so the
# default silently won. "Any batch" must mean any batch, regardless of
# whether a default batch is set.
class SearchLoaderNameAnyBatchOverridesDefaultBatchTest < ActionController::TestCase
  tests SearchController

  test "any batch target finds a record outside the default batch" do
    # Hardenbergia violacea lives in "Batch One" (see test/fixtures/loader/batch.yml
    # and test/fixtures/loader_names.yml). Setting "Batch Two" as the default
    # batch means a plain "loader names" search would miss it entirely - the
    # any-batch target must find it anyway.
    get(:search,
        params: { query_target: "loader names (any batch)", query_string: "Hardenbergia violacea" },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: [:login, :"batch-loader"],
                   default_loader_batch_name: "Batch Two" })
    assert_response :success
    assert_select "#search-results-summary",
                  /\b1 record*\b/,
                  "Any-batch target should find Hardenbergia violacea even though the default batch is 'Batch Two'"
  end

  test "plain loader names target, for contrast, is restricted to the default batch" do
    get(:search,
        params: { query_target: "loader names", query_string: "Hardenbergia violacea" },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: [:login, :"batch-loader"],
                   default_loader_batch_name: "Batch Two" })
    assert_response :success
    # Search::Base#empty is set once to false in set_defaults and never
    # reassigned - it does NOT mean "zero results", so it can't be used
    # here. An empty result set also renders no "0 records" text at all
    # (search/search_result_summary/_index.html.erb skips straight past
    # @search.empty without printing a count), so check the executed
    # query's actual row count instead, the same value the view would use
    # to render "N records" when there is at least one.
    assert_equal 0, assigns(:search).executed_query.count,
                 "Plain 'loader names' target should be restricted to the default batch " \
                 "'Batch Two' and so should NOT find Hardenbergia violacea, which lives in 'Batch One'"
  end
end
