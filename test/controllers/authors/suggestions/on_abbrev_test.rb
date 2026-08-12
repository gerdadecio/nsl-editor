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

# The stimulus-autocomplete flavour of the author-by-abbrev suggestions,
# used by the name form's Author field. Same query as the JSON action, but
# rendered as the HTML fragment the library expects.
class AuthorsSuggestionsOnAbbrevHtmlTest < ActionController::TestCase
  tests AuthorsController

  def get_suggestions(term)
    get(:typeahead_on_abbrev,
        params: { term: term, format: :html },
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

  test "should get author suggestions as an html fragment" do
    author = authors(:maslin_with_abbrev)

    get_suggestions("masl")

    assert_response :success
    assert_select_in_body(
      "li.autocomplete-result[data-autocomplete-value='#{author.id}']", true
    )
  end

  test "should bold the matched part of the abbrev" do
    get_suggestions("masl")

    assert_includes @response.body, "<strong>Masl</strong>in"
  end

  # Author::AsTypeahead.on_abbrev builds "<abbrev> | <extra information>" and
  # Name::AsResolvedTypeahead::ForAuthor parses that back by splitting on the
  # "|", so the label written into the visible input has to be exactly what
  # the server sent - including its spacing.
  test "should carry the unhighlighted value in data-autocomplete-label" do
    author = authors(:muller_f_with_umlaut)
    value = "#{author.abbrev}  | #{author.extra_information}"

    get_suggestions("fr.m")

    assert_select_in_body(
      "li.autocomplete-result[data-autocomplete-label='#{value}']", true
    )
  end

  test "should render a no matches option for a term matching nothing" do
    get_suggestions("no-such-author-abbrev")

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

  # The four author fields still on typeahead.js/Bloodhound ask the same
  # action for json, so the html format above must not have displaced it.
  test "should still answer json for the legacy typeahead fields" do
    author = authors(:maslin_with_abbrev)

    get(:typeahead_on_abbrev,
        params: { term: "masl", format: :json },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: ["edit"] })

    assert_response :success
    suggestions = JSON.parse(@response.body)
    assert_equal [author.id.to_s], suggestions.map { |s| s["id"] }
  end

  # Bloodhound sends no format extension - it asks by Accept header, through
  # jQuery, so the request is an XHR. Both parts matter: ActionDispatch
  # ignores "browser-like" Accept headers (anything containing ", */*")
  # unless the request is an XHR, in which case it honours them. Drop the
  # xhr: true below and this action answers html instead.
  test "should answer json when asked for by accept header on an xhr" do
    @request.headers["Accept"] = "application/json, text/javascript, */*; q=0.01"

    get(:typeahead_on_abbrev,
        params: { term: "masl" },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: ["edit"] },
        xhr: true)

    assert_response :success
    assert_equal "application/json", @response.media_type
  end
end
