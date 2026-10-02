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

# ReferencesController#typeahead_on_citation. Answers the shared html
# fragment to the instance forms' and profile v2 reference form's Reference
# fields, now on stimulus-autocomplete, and still offers json.
class ReferenceCitationSuggestionsForEditorTest < ActionDispatch::IntegrationTest
  setup do
    @reference = references(:cavanilles_icones)
  end

  def get_suggestions(term, format: :html)
    sign_in_as_fake_user(groups: [ "edit" ]) do
      get references_typeahead_on_citation_path(format: format),
          params: { term: term }
    end
  end

  def assert_select_in_body(*args, &block)
    assert_select(Nokogiri::HTML::DocumentFragment.parse(response.body),
                  *args, &block)
  end

  test "should get reference citation suggestions as an html fragment" do
    get_suggestions("cavanilles icones")

    assert_response :success
    assert_select_in_body(
      "li.autocomplete-result[data-autocomplete-value='#{@reference.id}']",
      true
    )
  end

  # The label is what the library writes back into the input on a pick:
  # the same display value the json carries.
  test "should label the option with the reference display value" do
    get_suggestions("cavanilles icones")

    assert_response :success
    assert_select_in_body(
      "li.autocomplete-result[data-autocomplete-value='#{@reference.id}']" \
      "[data-autocomplete-label='#{@reference.typeahead_display_value}']",
      true
    )
  end

  test "should render a no matches option for a blank term" do
    get_suggestions("")

    assert_response :success
    assert_select_in_body "li.autocomplete-result[aria-disabled='true']",
                          text: "No matches"
  end

  test "should answer an empty json array for a blank term" do
    get_suggestions("", format: :json)

    assert_response :success
    assert_equal [], JSON.parse(response.body)
  end

  test "should still answer json" do
    get_suggestions("cavanilles icones", format: :json)

    assert_response :success
    suggestions = JSON.parse(response.body)
    assert_includes suggestions.map { |s| s["id"] }, @reference.id.to_s
  end
end
