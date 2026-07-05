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
class SrchRefsDefinedQuerRefIdWithInstCountHasInst < ActionController::TestCase
  tests SearchController

  test "reference id with instances count" do
    skip # I want to retire this test because the defined query
    # is now replaced by show-instances:, but there isn't a count
    # option for show instances.  If demand for one I can add it.
    ref = references(:bucket_reference_for_default_instances)
    get(:search,
        params: { query_target: "instances for ref id",
                  query_string: "count #{ref.id}" },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: [] })
    assert_response :success
    assert_select "#search-results-summary",
                  /29 records\b/,
                  "Should show a correct count of records"
  end
end
