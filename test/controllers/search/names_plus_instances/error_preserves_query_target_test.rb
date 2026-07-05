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

# When a "Names plus instances" search raises a StandardError, the controller
# rewrites query_target to "name" before the error occurs.  The fix saves the
# original value in params[:original_query_target] and restores it inside
# run_empty_search_to_show_error, so the error page is rendered with the
# correct query target rather than the internal "name" rewrite.
#
# The show-novelties: directive raises a RuntimeError (StandardError subclass)
# for the "name" target (only allowed for "references"), giving us a reliable
# way to exercise the error path without a database error.
class NamesSearchControllerNamesAndInstancesErrorPreservesQueryTargetTest < ActionController::TestCase
  tests SearchController

  test "error during Names plus instances search preserves original query target in rendered form" do
    get(:search,
        params: { query_target: "Names plus instances",
                  query_string: "angophora show-novelties:" },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: [] })
    assert_response :success
    assert_select "input#query-target[value=?]", "Names plus instances"
  end
end
