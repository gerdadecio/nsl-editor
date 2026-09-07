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

# NamesController#hybrid_parent_suggestions. Answers the shared html
# fragment to the name form's Parent field, now on stimulus-autocomplete,
# and json to the Second parent field, still on typeahead.js.
class NameHybridParentSuggestionsForEditorTest < ActionController::TestCase
  tests NamesController

  def get_suggestions(term, format: :html)
    get(:hybrid_parent_suggestions,
        params: { rank_id: name_ranks(:unranked).id,
                  term: term,
                  format: format },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: ["edit"] })
  end

  def assert_select_in_body(*args, &block)
    assert_select(Nokogiri::HTML::DocumentFragment.parse(@response.body),
                  *args, &block)
  end

  test "should get name hybrid parent suggestions as an html fragment" do
    get_suggestions("a_spec")

    assert_response :success
    assert_select_in_body(
      "li.autocomplete-result[data-autocomplete-value='#{names(:a_species).id}']",
      true
    )
  end

  # A hybrid's suggestions carry no family, so picking one leaves the
  # Family field alone - as the old typeahead.js wiring also did.
  test "should not publish a family on the option" do
    get_suggestions("a_spec")

    assert_response :success
    assert_select_in_body "li.autocomplete-result[data-family-id]", false
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
    assert_includes suggestions.map { |s| s["id"] }, names(:a_species).id
  end
end
