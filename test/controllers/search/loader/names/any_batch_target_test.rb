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

# Single search controller test.
#
# Exercises the new "Loader names (any batch)" search target - a distinct
# dropdown item that explicitly searches across all batches, alongside the
# plain "Loader names" target. The browser submits the link's literal text
# as query_target, e.g. "Loader names (any batch)", which Search::Base
# canonicalizes to "loader_names_(any_batch)" before ParsedRequest strips
# the parens down to "loader_names_any_batch".
class SearchLoaderNameAnyBatchTargetTest < ActionController::TestCase
  tests SearchController

  test "loader names (any batch) target does not require a default batch" do
    get(:search,
        params: { query_target: "loader names (any batch)", query_string: "*" },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: [:login, :"batch-loader"] })
    assert_response :success
    assert_not_select "#search-results-summary",
                       /Please set a default batch/,
                       "Should not be asked to set a default batch"
  end

  test "loader names (any batch) target searches across batches without an explicit any-batch directive" do
    get(:search,
        params: { query_target: "loader names (any batch)", query_string: "Hardenbergia violacea" },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: [:login, :"batch-loader"] })
    assert_response :success
    assert_select "#search-results-summary",
                  /\b1 record*\b/,
                  "Should find one loader name record for Hardenbergia violacea across all batches"
  end
end
