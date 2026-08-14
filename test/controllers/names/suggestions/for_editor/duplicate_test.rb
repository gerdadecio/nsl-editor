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

# NamesController#duplicate_suggestions, used by the name form's Duplicate
# of field. Now shares its html rendering with every other migrated field
# (app/views/shared/_autocomplete_suggestions.html.erb) rather than a
# duplicate-of-specific partial - mirrors
# test/controllers/authors/suggestions/on_abbrev_test.rb, the sibling field
# these shared resources were generalised from.
class NameDuplicateSuggestionsForEditorTest < ActionController::TestCase
  tests NamesController

  def get_suggestions(term, name_id, format: :html)
    get(:duplicate_suggestions,
        params: { term: term, name_id: name_id, format: format },
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

  test "should get name duplicate suggestions as an html fragment" do
    match = names(:angophora_costata)
    current = names(:angophora)

    get_suggestions("ang", current.id)

    assert_response :success
    assert_select_in_body(
      "li.autocomplete-result[data-autocomplete-value='#{match.id}']", true
    )
  end

  test "should bold the matched part of the name" do
    current = names(:angophora)

    get_suggestions("ang", current.id)

    assert_includes @response.body, "<strong>Ang</strong>"
  end

  # extra_params on the shared autocomplete field carries the current
  # record's own id through as name_id (see
  # app/views/names/form/_duplicate_of.html.erb), so a name is never
  # offered as a duplicate of itself.
  test "should not offer the current name as a duplicate of itself" do
    current = names(:angophora)

    get_suggestions("angophora", current.id)

    assert_response :success
    assert_select_in_body(
      "li.autocomplete-result[data-autocomplete-value='#{current.id}']", false
    )
  end

  test "should render a no matches option for a term matching nothing" do
    current = names(:angophora)

    get_suggestions("no-such-name-at-all", current.id)

    assert_response :success
    assert_select_in_body "li.autocomplete-result[aria-disabled='true']",
                          text: "No matches"
  end

  test "should render a no matches option for a blank term" do
    get_suggestions("", names(:angophora).id)

    assert_response :success
    assert_select_in_body "li.autocomplete-result[aria-disabled='true']",
                          text: "No matches"
  end

  test "should still answer json" do
    match = names(:angophora_costata)
    current = names(:angophora)

    get_suggestions("ang", current.id, format: :json)

    assert_response :success
    suggestions = JSON.parse(@response.body)
    assert_includes suggestions.map { |s| s["id"] }, match.id
  end
end
