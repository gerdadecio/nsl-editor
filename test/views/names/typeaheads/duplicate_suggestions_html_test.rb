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

# Renders the stimulus-autocomplete HTML fragment for the Name
# "duplicate of" field.
class DuplicateSuggestionsHtmlPartialTest < ActionView::TestCase
  def render_suggestions(suggestions, term)
    render partial: "names/typeaheads/duplicate_suggestions_html",
           locals: { suggestions: suggestions, term: term }
    rendered
  end

  test "bolds the matched substring within a suggestion" do
    suggestions = [{ value: "Angiospermae | legitimate", id: 123 }]

    output = render_suggestions(suggestions, "ang")

    assert_includes output, "<strong>Ang</strong>iospermae"
  end

  test "renders the option's id as data-autocomplete-value" do
    suggestions = [{ value: "Angiospermae | legitimate", id: 123 }]

    output = render_suggestions(suggestions, "ang")

    assert_select_in output, "li.duplicate-of-autocomplete-result[data-autocomplete-value='123']"
  end

  test "renders a 'No matches' option, still styled, when there are no suggestions" do
    output = render_suggestions([], "xyz")

    assert_select_in output, "li.duplicate-of-autocomplete-result[aria-disabled='true']", text: "No matches"
  end

  def assert_select_in(html, *args, &block)
    assert_select(Nokogiri::HTML::DocumentFragment.parse(html), *args, &block)
  end
end
