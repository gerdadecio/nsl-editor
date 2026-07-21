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

# Regression test: SearchController#search used to rescue
# ActiveRecord::StatementInvalid by building a Search::Error, a class that
# does not exist anywhere in the codebase. That meant a malformed-query SQL
# error would crash the rescue handler itself (NameError: uninitialized
# constant Search::Error) instead of showing the friendly
# "That query did not work" message. The fix routes this rescue through the
# same run_empty_search_to_show_error helper already used - and already
# proven safe - by the generic StandardError rescue below it.
class SearchControllerStatementInvalidTest < ActionController::TestCase
  tests SearchController

  test "a StatementInvalid error during search renders the search page instead of crashing" do
    SearchController.stub_any_instance(
      :run_local_search,
      -> { raise ActiveRecord::StatementInvalid, "malformed SQL" }
    ) do
      get(:search,
          params: { query_target: "Names", query_string: "angophora" },
          session: { username: "fred",
                     user_full_name: "Fred Jones",
                     groups: [] })
    end

    assert_response :success
    assert_match(/That query did not work/, response.body)
  end
end
