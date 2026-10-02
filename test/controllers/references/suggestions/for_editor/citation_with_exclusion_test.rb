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

# ReferencesController#typeahead_on_citation_with_exclusion. Answers the
# shared html fragment to the copy to new reference tab's Reference field,
# now on stimulus-autocomplete, leaving out the excluded reference.
class ReferenceCitationWithExclusionSuggestionsForEditorTest < ActionDispatch::IntegrationTest
  setup do
    @reference = references(:cavanilles_icones)
  end

  def get_suggestions(term, excluded_id: -1, format: :html)
    sign_in_as_fake_user(groups: [ "edit" ]) do
      get references_typeahead_on_citation_with_exclusion_path(excluded_id, format: format),
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
      "li.autocomplete-result[data-autocomplete-value='#{@reference.id}']" \
      "[data-autocomplete-label='#{@reference.typeahead_display_value}']",
      true
    )
  end

  test "should leave out the excluded reference" do
    get_suggestions("cavanilles icones", excluded_id: @reference.id)

    assert_response :success
    assert_select_in_body(
      "li.autocomplete-result[data-autocomplete-value='#{@reference.id}']",
      false
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

  test "should still answer json, without the excluded reference" do
    get_suggestions("cavanilles icones", excluded_id: @reference.id, format: :json)

    assert_response :success
    assert_not_includes JSON.parse(response.body).map { |s| s["id"] }, @reference.id.to_s
  end
end
