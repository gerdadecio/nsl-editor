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

# The name's new instance form (names - instances tab) renders its
# Reference field on stimulus-autocomplete, through the shared partial,
# with the dom ids other JS keys off unchanged.
class NameInstanceCreateReferenceFieldTest < ActionController::TestCase
  tests NamesController

  setup do
    @name = names(:a_species)
  end

  test "should render the reference field as a stimulus autocomplete" do
    @request.headers["Accept"] = "application/javascript"
    get(
      :show,
      params: { id: @name.id, tab: "tab_instances" },
      session: {
        username: "fred",
        user_full_name: "Fred Jones",
        groups: ["edit"],
      },
      xhr: true,
    )

    assert_response :success
    assert_select "div.autocomplete[data-controller='autocomplete']" \
                  "[data-autocomplete-url-value='/references/typeahead/on_citation.html']" \
                  " input#instance-reference-typeahead" \
                  "[data-autocomplete-target='input'][required]",
                  true
    assert_select "div.autocomplete" \
                  " input#instance_reference_id" \
                  "[data-autocomplete-target='hidden']",
                  true
    # The hidden reference_id is rendered once, by the partial, not also by
    # the form as it used to be.
    assert_select "input#instance_reference_id", count: 1
    # No label of its own: the field sits inside the form's sentence.
    assert_select "div.autocomplete label", false
    assert_no_match(/setUpInstanceReference\(\)/, response.body)
  end
end
