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

# ReferencesController#typeahead_on_citation_for_parent. Answers the shared
# html fragment to the reference form's Parent field, now on
# stimulus-autocomplete. Offers only references of a type that can contain
# the type chosen on the form, and leaves out the current reference.
class ReferenceCitationForParentSuggestionsForEditorTest < ActionDispatch::IntegrationTest
  setup do
    @paper = references(:a_paper)
    @journal = references(:journal_for_citation_for_parent_test)
  end

  def get_suggestions(term, current_id: @paper.id, ref_type_id: ref_types(:paper).id,
                      format: :html, groups: [ "edit" ])
    sign_in_as_fake_user(groups: groups) do
      get references_typeahead_on_citation_for_parent_path(format: format),
          params: { term: term, id: current_id, ref_type_id: ref_type_id }
    end
  end

  def assert_select_in_body(*args, &block)
    assert_select(Nokogiri::HTML::DocumentFragment.parse(response.body),
                  *args, &block)
  end

  test "should get parent suggestions as an html fragment" do
    get_suggestions("journal_one_word and more")

    assert_response :success
    assert_select_in_body(
      "li.autocomplete-result[data-autocomplete-value='#{@journal.id}']" \
      "[data-autocomplete-label='#{@journal.typeahead_display_value}']",
      true
    )
  end

  test "should bold the matched part of the citation" do
    get_suggestions("journal_one_word")

    assert_includes response.body, "<strong>journal_one_word</strong>"
  end

  # The type on the form, not the saved one, decides: a book's parent is a
  # series, so no journal is offered.
  test "should restrict suggestions to the ref type sent" do
    get_suggestions("journal_one_word", ref_type_id: ref_types(:book).id)

    assert_response :success
    assert_select_in_body(
      "li.autocomplete-result[data-autocomplete-value='#{@journal.id}']",
      false
    )
  end

  test "should leave out the current reference" do
    get_suggestions("journal_one_word and more", current_id: @journal.id)

    assert_response :success
    assert_select_in_body(
      "li.autocomplete-result[data-autocomplete-value='#{@journal.id}']",
      false
    )
  end

  # A new reference has no id yet, so the field sends it empty.
  test "should offer suggestions for a new reference with no id" do
    get_suggestions("journal_one_word and more", current_id: "")

    assert_response :success
    assert_select_in_body(
      "li.autocomplete-result[data-autocomplete-value='#{@journal.id}']",
      true
    )
  end

  test "should render a no matches option for a blank term" do
    get_suggestions("")

    assert_response :success
    assert_select_in_body "li.autocomplete-result[aria-disabled='true']",
                          text: "No matches"
  end

  test "should forbid a user without edit rights" do
    get_suggestions("journal_one_word", groups: [])

    assert_response :forbidden
    assert_no_match "autocomplete-result", response.body
  end

  test "should still answer json when asked for it" do
    get_suggestions("journal_one_word and more", format: :json)

    assert_response :success
    assert_includes JSON.parse(response.body).map { |s| s["id"] }, @journal.id.to_s
  end

  test "should answer an empty json array for a blank term" do
    get_suggestions("", format: :json)

    assert_response :success
    assert_equal [], JSON.parse(response.body)
  end
end
