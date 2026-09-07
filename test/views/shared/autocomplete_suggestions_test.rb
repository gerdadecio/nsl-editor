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

# Renders the stimulus-autocomplete HTML fragment shared by every migrated
# typeahead field.
class AutocompleteSuggestionsPartialTest < ActionView::TestCase
  def render_suggestions(suggestions, term, **locals)
    render partial: "shared/autocomplete_suggestions",
           locals: { suggestions: suggestions, term: term }.merge(locals)
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

    assert_select_in output, "li.autocomplete-result[data-autocomplete-value='123']"
  end

  test "renders the unhighlighted value as data-autocomplete-label" do
    suggestions = [{ value: "Angiospermae | legitimate", id: 123 }]

    output = render_suggestions(suggestions, "ang")

    assert_select_in output,
                     "li.autocomplete-result[data-autocomplete-label='Angiospermae | legitimate']"
  end

  test "preserves an author-shaped value's spacing in data-autocomplete-label" do
    # Author::AsTypeahead.on_abbrev builds "<abbrev> | <extra information>",
    # and Name::AsResolvedTypeahead::ForAuthor parses it back by splitting on
    # the "|", so the label has to be what the server sent - not the trimmed
    # textContent the library would otherwise fall back to.
    suggestions = [{ value: "Benth.  | George Bentham", id: 7 }]

    output = render_suggestions(suggestions, "ben")

    assert_select_in output,
                     "li.autocomplete-result[data-autocomplete-label='Benth.  | George Bentham']"
  end

  # For a field that has to act on more than the picked record's id: the
  # name form's Parent field fills in the Family field from the parent's
  # own family, see
  # app/javascript/controllers/name_parent_family_controller.js.
  test "publishes the keys named in data_keys as data attributes" do
    suggestions = [{ value: "a_genus | Genus", id: 123,
                     family_id: 7, family_value: "a_family" }]

    output = render_suggestions(suggestions, "a_gen",
                                data_keys: %i[family_id family_value])

    assert_select_in output,
                     "li.autocomplete-result[data-family-id='7']" \
                     "[data-family-value='a_family']"
  end

  test "publishes no extra data attributes without data_keys" do
    suggestions = [{ value: "a_genus | Genus", id: 123, family_id: 7 }]

    output = render_suggestions(suggestions, "a_gen")

    assert_select_in output, "li.autocomplete-result[data-family-id]", false
  end

  test "renders a 'No matches' option, still styled, when there are no suggestions" do
    output = render_suggestions([], "xyz")

    assert_select_in output, "li.autocomplete-result[aria-disabled='true']", text: "No matches"
  end

  def assert_select_in(html, *args, &block)
    assert_select(Nokogiri::HTML::DocumentFragment.parse(html), *args, &block)
  end
end
