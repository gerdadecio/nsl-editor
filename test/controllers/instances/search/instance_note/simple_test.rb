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

# Single controller test.
class InstanceSearchOnInstanceNoteSimpleTest < ActionController::TestCase
  tests SearchController

  test "instance search on instance note with simple text" do
    instance = instances(:triodia_in_brassard)
    get(:search,
        params: ActiveSupport::HashWithIndifferentAccess.new(
          query_target: "instance",
          query_string: "note: *ystrin*"
        ),
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: [] })
    assert_response :success
    assert_select "span#search-results-summary", true, "Should find 1 record"
    assert_select "span#search-results-summary",
                  /\b1 record\b/,
                  "Should find 1 record"
    assert_select "tr#search-result-#{instance.id}",
                  true,
                  "Should find the instance."
  end
end
