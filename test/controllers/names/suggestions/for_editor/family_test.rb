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

# NamesController#name_family_suggestions, used by the name form's Family
# field, which is now a stimulus-autocomplete field - so the action answers
# the shared html fragment as well as the json it always has. Mirrors
# test/controllers/names/suggestions/for_editor/parent_test.rb, the sibling
# field migrated just before it.
class NameFamilySuggestionsForEditorTest < ActionController::TestCase
  tests NamesController
  setup do
    @name = names(:a_species)
  end

  # name_id and rank_id ride along because the field sends them, as the
  # typeahead.js widget before it did.
  def get_suggestions(term, format: :html)
    get(:name_family_suggestions,
        params: { term: term,
                  rank_id: name_ranks(:species).id,
                  name_id: @name.id,
                  format: format },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: ["edit"] })
  end

  # The response is a bare list of <li> elements with no enclosing <ul>, so
  # parse it as a fragment rather than letting assert_select treat it as a
  # whole document.
  def assert_select_in_body(*args, &block)
    assert_select(Nokogiri::HTML::DocumentFragment.parse(@response.body),
                  *args, &block)
  end

  test "should get name family suggestions as an html fragment" do
    get_suggestions("a_fam")

    assert_response :success
    assert_select_in_body(
      "li.autocomplete-result[data-autocomplete-value='#{names(:a_family).id}']",
      true
    )
  end

  test "should bold the matched part of the name" do
    get_suggestions("a_fam")

    assert_includes @response.body, "<strong>a_fam</strong>"
  end

  # Only names of family rank are offered - the field is asking which family
  # the name belongs to, not for any name at all.
  test "should not suggest a name that is not a family" do
    get_suggestions("a_gen")

    assert_response :success
    assert_select_in_body "li.autocomplete-result[aria-disabled='true']",
                          text: "No matches"
  end

  test "should render a no matches option for a term matching nothing" do
    get_suggestions("no-such-name-at-all")

    assert_response :success
    assert_select_in_body "li.autocomplete-result[aria-disabled='true']",
                          text: "No matches"
  end

  test "should render a no matches option for a blank term" do
    get_suggestions("")

    assert_response :success
    assert_select_in_body "li.autocomplete-result[aria-disabled='true']",
                          text: "No matches"
  end

  test "should still answer json" do
    get_suggestions("a_fam", format: :json)

    assert_response :success
    suggestions = JSON.parse(@response.body)
    assert_includes suggestions.map { |s| s["id"] }, names(:a_family).id
  end
end
