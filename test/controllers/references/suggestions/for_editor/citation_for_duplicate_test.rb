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

# ReferencesController#typeahead_on_citation_for_duplicate. Answers the
# shared html fragment to the reference form's Duplicate of field, now on
# stimulus-autocomplete. Leaves out the current reference, and for a
# reference of a known type, references of other known types.
class ReferenceCitationForDuplicateSuggestionsForEditorTest < ActionDispatch::IntegrationTest
  setup do
    @unknown_type = references(:an_unknown_type_invalid_child_of_book)
    @master = references(:a_section_type_intended_master)
  end

  def get_suggestions(term, current_id: @unknown_type.id, format: :html, groups: [ "edit" ])
    sign_in_as_fake_user(groups: groups) do
      get references_typeahead_on_citation_for_duplicate_path(id: current_id, format: format),
          params: { term: term }
    end
  end

  def assert_select_in_body(*args, &block)
    assert_select(Nokogiri::HTML::DocumentFragment.parse(response.body),
                  *args, &block)
  end

  test "should get duplicate suggestions as an html fragment" do
    get_suggestions("section type intended master")

    assert_response :success
    assert_select_in_body(
      "li.autocomplete-result[data-autocomplete-value='#{@master.id}']" \
      "[data-autocomplete-label='#{@master.typeahead_display_value}']",
      true
    )
  end

  test "should bold the matched part of the citation" do
    get_suggestions("intended")

    assert_includes response.body, "<strong>intended</strong>"
  end

  test "should leave out the current reference" do
    get_suggestions("unknown invalidly child of book")

    assert_response :success
    assert_select_in_body(
      "li.autocomplete-result[data-autocomplete-value='#{@unknown_type.id}']",
      false
    )
  end

  test "should leave out references of another known type" do
    get_suggestions("section type intended master", current_id: references(:a_book).id)

    assert_response :success
    assert_select_in_body(
      "li.autocomplete-result[data-autocomplete-value='#{@master.id}']",
      false
    )
  end

  test "should render a no matches option for a blank term" do
    get_suggestions("")

    assert_response :success
    assert_select_in_body "li.autocomplete-result[aria-disabled='true']",
                          text: "No matches"
  end

  test "should forbid a user without edit rights" do
    get_suggestions("section type intended master", groups: [])

    assert_response :forbidden
    assert_no_match "autocomplete-result", response.body
  end

  test "should still answer json when asked for it" do
    get_suggestions("section type intended master", format: :json)

    assert_response :success
    assert_includes JSON.parse(response.body).map { |s| s["id"] }, @master.id.to_s
  end

  test "should answer an empty json array for a blank term" do
    get_suggestions("", format: :json)

    assert_response :success
    assert_equal [], JSON.parse(response.body)
  end
end
