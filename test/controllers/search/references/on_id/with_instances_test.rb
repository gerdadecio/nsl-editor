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
class SearchRefsOnIdWithInstancesTest < ActionController::TestCase
  tests SearchController

  test "search on reference id with show-instances" do
    run_search("show-instances:")
  end

  test "search on reference id with s-i abbrev" do
    run_search("s-i:")
  end

  test "search on reference id with si abbrev" do
    run_search("si:")
  end

  test "search on reference id with i abbrev" do
    run_search("i:")
  end

  def run_search(directive)
    ref = references(:bucket_reference_for_default_instances)
    get(:search,
        params: { query_target: "reference",
                  query_string: "id: #{ref.id} #{directive}" },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: [] })
    assert_response :success
    # NOTES (limit/total redesign, follow-up): a single matching reference
    # is 1 record, full stop - its attached instances are shown but no
    # longer folded into the "N records" count (see
    # Search::OnModel::Base#run_list_query and
    # search/search_result_summary/_list.html.erb). Used to assert
    # "37 records" (1 reference + 36 fixture instances, interleaved).
    assert_select "#search-results-summary",
                  /1 record\b/,
                  "Should find 1 record"
  end
end
