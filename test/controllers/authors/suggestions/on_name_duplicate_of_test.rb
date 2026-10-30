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

# The stimulus-autocomplete flavour of the author duplicate-of suggestions,
# used by the author form's Duplicate of field. Same query as the JSON
# response, but rendered as the HTML fragment the library expects.
class AuthorsSuggestionsOnNameDuplicateOfTest < ActionDispatch::IntegrationTest
  def get_suggestions(term, author: authors(:clarke_1), format: :html)
    sign_in_as_fake_user(
      username: "fred",
      full_name: "Fred Jones",
      groups: [ "edit" ]
    ) do
      get authors_typeahead_on_name_duplicate_of_current_path(
        id: author.id, term: term, format: format
      )
    end
  end

  # The response is a bare list of <li> elements with no enclosing <ul>, so
  # parse it as a fragment rather than letting assert_select treat it as a
  # whole document.
  def assert_select_in_body(*args, &block)
    assert_select(
      Nokogiri::HTML::DocumentFragment.parse(@response.body),
      *args,
      &block
    )
  end

  test "should get duplicate of suggestions as an html fragment" do
    get_suggestions("clarke")

    assert_response :success
    assert_select_in_body(
      "li.autocomplete-result[data-autocomplete-value='#{authors(:clarke_2).id}']",
      true
    )
  end

  test "should not offer the author being edited" do
    get_suggestions("clarke")

    assert_select_in_body(
      "li.autocomplete-result[data-autocomplete-value='#{authors(:clarke_1).id}']",
      false
    )
  end

  test "should bold the matched part of the name" do
    get_suggestions("clar")

    assert_includes @response.body, "<strong>clar</strong>ke2"
  end

  # Author::AsTypeahead.on_name_duplicate_of builds
  # "<name> | <n> refs | <abbrev>" and
  # Author::AsResolvedTypeahead::ForDuplicateOf cuts that at the first "|",
  # so the label written into the visible input has to be exactly what the
  # server sent.
  test "should carry the unhighlighted value in data-autocomplete-label" do
    get_suggestions("masl", author: authors(:clarke_1))

    assert_select_in_body(
      "li.autocomplete-result[data-autocomplete-label='Maslin, B.R. | Maslin']",
      true
    )
  end

  test "should render a no matches option for a term matching nothing" do
    get_suggestions("no-such-author-name")

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

  # Read-only users can see an author's details tab but nothing else of
  # AuthorsController, so they can't list authors through this endpoint.
  test "should forbid a user without edit rights" do
    sign_in_as_fake_user(
      username: "fred",
      full_name: "Fred Jones",
      groups: []
    ) do
      get authors_typeahead_on_name_duplicate_of_current_path(
        id: authors(:clarke_1).id, term: "clarke", format: :html
      )
    end

    assert_response :forbidden
    assert_no_match "autocomplete-result", @response.body
  end

  test "should still answer json when asked for it" do
    get_suggestions("clarke", format: :json)

    assert_response :success
    ids = JSON.parse(@response.body).map { |s| s["id"] }
    assert_includes ids, authors(:clarke_2).id.to_s
    assert_not_includes ids, authors(:clarke_1).id.to_s
  end
end
