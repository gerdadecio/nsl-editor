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

# Single reference controller test.
class ReferenceEditorShowNewInstanceTabTest < ActionController::TestCase
  tests ReferencesController
  setup do
    @reference = references(:a_book)
  end

  test "should show editor reference new instance tab" do
    @request.headers["Accept"] = "application/javascript"
    get(:show,
        params: { id: @reference.id, tab: "tab_new_instance" },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: ["edit"] })
    assert_select "li.active a#reference-new-instance-tab",
                  /New instance/,
                  "Should show 'New instance' tab."
    assert_select "form", true
  end

  # The form's Name field is on stimulus-autocomplete, rendered through
  # the shared partial, with the dom ids other JS and the controller's
  # error handling key off unchanged.
  test "should render the name field as a stimulus autocomplete" do
    @request.headers["Accept"] = "application/javascript"
    get(:show,
        params: { id: @reference.id, tab: "tab_new_instance" },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: ["edit"] })
    assert_response :success
    assert_select "div.autocomplete[data-controller='autocomplete']" \
                  "[data-autocomplete-url-value='/names/typeahead_on_full_name.html']" \
                  " input#instance-name-typeahead" \
                  "[data-autocomplete-target='input']",
                  true
    assert_select "div.autocomplete" \
                  " input#instance_name_id" \
                  "[data-autocomplete-target='hidden']",
                  true
    # The hidden name_id is rendered once, by the partial, not also by the
    # form as it used to be.
    assert_select "input#instance_name_id", count: 1
    # No label of its own: the field sits inside the form's sentence.
    assert_select "div.autocomplete label", false
    assert_no_match(/setUpInstanceName\(\)/, @response.body)
  end
end
