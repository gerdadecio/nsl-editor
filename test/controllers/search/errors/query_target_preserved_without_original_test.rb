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

# Regression test: run_empty_search_to_show_error used to unconditionally set
# params[:query_target] = params[:original_query_target]. original_query_target
# is only ever set for a "Names plus instances" search (see
# handle_names_plus_instances_target), so for every other target this wiped
# query_target to nil, and the error page's target button silently fell back
# to the "Names" default (Search::EmptyParsedRequest#target_button_text) -
# even though the user had actually searched, say, "References".
#
# The fix only falls back to query_target when original_query_target is
# blank, so the user's actual target survives onto the error page.
class SearchControllerQueryTargetPreservedWithoutOriginalTest < ActionController::TestCase
  tests SearchController

  test "an error during a non-'Names plus instances' search preserves the actual query target" do
    SearchController.stub_any_instance(
      :run_local_search,
      -> { raise StandardError, "boom" }
    ) do
      get(:search,
          params: { query_target: "References", query_string: "linnaeus" },
          session: { username: "fred",
                     user_full_name: "Fred Jones",
                     groups: [] })
    end

    assert_response :success
    assert_select "#search-target-button-text", /References/
  end
end
