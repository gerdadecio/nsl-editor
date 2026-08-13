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

# Regression test: query_target_preserved_without_original_test.rb's fix
# (preserve params[:query_target] onto the error page for errors unrelated
# to the target) had a side effect for the one error that IS about the
# target: searching on an unrecognised query_target like "fred" used to
# echo that raw, invalid value straight into the search-target button,
# rather than falling back to a real target the way it did before that
# fix. The error message itself correctly names the bad target - that's
# unchanged and intentional - but the button is a control that should only
# ever hold a real target.
class SearchControllerInvalidQueryTargetResetsButtonTest < ActionController::TestCase
  tests SearchController

  test "an unknown query target shows the error but resets the target button to the default" do
    get(:search,
        params: { query_target: "fred", query_string: "ang" },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: [] })

    assert_response :success
    assert_select "#search-target-button-text", /Names/
    assert_select "#search-target-button-text" do |elements|
      assert_no_match(/fred/, elements.first.text)
    end
    assert_select "#search-results-summary", /Unknown query target.*fred/
  end

  test "an error unrelated to the target still preserves the actual query target" do
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
