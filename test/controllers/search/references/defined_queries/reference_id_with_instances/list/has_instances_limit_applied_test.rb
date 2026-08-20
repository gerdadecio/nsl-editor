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
# NOTES (limit/total redesign): this used to assert that `limit:10`
# capped a reference's own instance list to 10 rows - that was exactly
# the behaviour being removed (Instance::AsArray::ForReference no longer
# takes a limit: from search callers, same as Instance::AsArray::ForName
# never having had one). Repurposed to assert the new invariant instead:
# `limit:` still governs how many References a search returns, but no
# longer truncates any single reference's instance list.
#
# Not asserting an exact record count here (bucket_reference_for_default_instances
# has 36 fixture instances at time of writing, i.e. 37 rows with the
# reference itself, but that's incidental to what this test protects) -
# what matters is that it's well over the limit:10 that used to cap it.
class SrchRefsDefQueriesRefIdWInstListHasInstWLimit < ActionController::TestCase
  tests SearchController

  test "limit: no longer truncates a single reference's instance list" do
    ref = references(:bucket_reference_for_default_instances)
    get(:search,
        params: { query_target: "references",
                  query_string: "id: #{ref.id} show-instances: limit:10" },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: [] })
    assert_response :success
    assert_select "#search-results-summary" do |elements|
      text = elements.first.text
      count = text[/([0-9]+) records?/, 1].to_i
      assert_operator count, :>, 10,
                       "Expected more than the old limit:10 cap - got: #{text.strip}"
    end
  end
end
