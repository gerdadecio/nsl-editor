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

# NamesController#typeahead_on_full_name. Answers the shared html fragment
# to the instance form's Name field (references - new instance tab), now on
# stimulus-autocomplete, and still offers json for parity with the other
# suggestion actions.
class NameFullNameSuggestionsForEditorTest < ActionController::TestCase
  tests NamesController
  setup do
    @name = names(:a_species)
  end

  def get_suggestions(term, format: :html)
    get(
      :typeahead_on_full_name,
      params: { term: term, format: format },
      session: {
        username: "fred",
        user_full_name: "Fred Jones",
        groups: ["edit"],
      },
    )
  end

  def assert_select_in_body(*args, &block)
    assert_select(
      Nokogiri::HTML::DocumentFragment.parse(@response.body),
      *args,
      &block
    )
  end

  test "should get name full name suggestions as an html fragment" do
    get_suggestions("a_spec")

    assert_response :success
    assert_select_in_body(
      "li.autocomplete-result[data-autocomplete-value='#{@name.id}']",
      true,
    )
  end

  # The label is what the library writes back into the input on a pick:
  # the full name and status the json value also carries.
  test "should label the option with the full name and status" do
    get_suggestions("a_spec")

    assert_response :success
    assert_select_in_body(
      "li.autocomplete-result[data-autocomplete-value='#{@name.id}']" \
        "[data-autocomplete-label='#{@name.full_name} - #{@name.name_status.name}']",
      true,
    )
  end

  test "should render a no matches option for a blank term" do
    get_suggestions("")

    assert_response :success
    assert_select_in_body "li.autocomplete-result[aria-disabled='true']",
      text: "No matches"
  end

  test "should still answer json" do
    get_suggestions("a_spec", format: :json)

    assert_response :success
    suggestions = JSON.parse(@response.body)
    assert_includes suggestions.map { |s| s["id"] }, @name.id
  end
end
