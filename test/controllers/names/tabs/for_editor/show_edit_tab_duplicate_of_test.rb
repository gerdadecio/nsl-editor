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

# The "Duplicate of" field's stimulus-autocomplete wiring on the name edit
# tab.
class ShowEditTabDuplicateOfTest < ActionController::TestCase
  tests NamesController
  setup do
    @name = names(:a_species)
  end

  def show_edit_tab
    @request.headers["Accept"] = "application/javascript"
    get(:show,
        params: { id: @name.id, tab: "tab_edit" },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: ["edit"] })
    assert_response :success
  end

  def duplicate_of_wrapper
    "div.nsl-autocomplete" \
      "[data-nsl-autocomplete-url-value$='/suggestions/name/duplicate_html']"
  end

  # The record's own id has to reach the suggestions request, or a name
  # would be offered as a duplicate of itself. It travels as extra_params,
  # which NslAutocompleteController#buildURL merges into the query string.
  # Without it names#duplicate_suggestions_html returns no suggestions at
  # all, so losing this fails quietly - hence the test.
  test "passes the record's own id along with every suggestions request" do
    show_edit_tab

    assert_select "#{duplicate_of_wrapper}[data-nsl-autocomplete-extra-params-value=?]",
                  {name_id: @name.id}.to_json
  end

  test "wires the input, hidden and results targets to the controller" do
    show_edit_tab

    assert_select "#{duplicate_of_wrapper}[data-controller='nsl-autocomplete']"
    assert_select "input#duplicate-of-typeahead[data-nsl-autocomplete-target='input']" \
                  "[name='name[duplicate_of_typeahead]']"
    assert_select "div.nsl-autocomplete input#name_duplicate_of_id" \
                  "[data-nsl-autocomplete-target='hidden']"
    assert_select "#{duplicate_of_wrapper} ul.nsl-autocomplete-results" \
                  "[data-nsl-autocomplete-target='results']"
  end
end
