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

# Single reference controller test.
class ReferenceEditorShowEdit1TabTest < ActionDispatch::IntegrationTest
  setup do
    @reference = references(:a_book)
  end

  test "should show editor reference edit 1 tab" do
    sign_in_as_fake_user(
      username: "fred",
      full_name: "Fred Jones",
      groups: [ "edit" ]
    ) do
      get reference_tab_path(id: @reference.id, tab: "tab_edit_1"),
        headers: { "Accept" => "application/javascript" }
    end
    assert_select "li.active a#reference-edit-1-tab",
                  /Edit\./,
                  "Should show 'Edit 1' tab."
    assert_select "form", true
    assert_select "select#reference_ref_type_id", true
    assert_select "input#reference-parent-typeahead", true
    assert_select "input#reference_title", true
    assert_select "input#reference_published", true
    assert_select "input#reference-author-typeahead", true
    assert_select "select#reference_ref_author_role_id", true
    assert_select "input#reference_edition", true
    assert_select "input#reference_volume", true
    assert_select "input#reference_pages", true
    assert_select "input#reference_day", true
    assert_select "select#reference_month", true
    assert_select "input#reference_year", true
    assert_select "input#reference_publication_date", true
    assert_select "textarea#reference_notes", true
  end

  # Author is on the shared stimulus-autocomplete markup
  # (app/views/shared/_autocomplete_field), not typeahead.js.
  test "should render the author field as a stimulus autocomplete" do
    sign_in_as_fake_user(
      username: "fred",
      full_name: "Fred Jones",
      groups: [ "edit" ]
    ) do
      get reference_tab_path(id: @reference.id, tab: "tab_edit_1"),
        headers: { "Accept" => "application/javascript" }
    end
    assert_response :success
    url = authors_typeahead_on_name_path(format: :html)
    assert_select "div.autocomplete[data-controller='autocomplete']" \
      "[data-autocomplete-url-value='#{url}']" \
      "[data-autocomplete-term-delimiter-value='|'] " \
      "input#reference-author-typeahead[data-autocomplete-target='input']" \
      "[name='reference[author_typeahead]'][required]",
                  true
    assert_select "div.autocomplete " \
      "input#reference_author_id[data-autocomplete-target='hidden']",
                  true
    assert_select "div.autocomplete ul[data-autocomplete-target='results']",
                  true
    assert_select "div.autocomplete label[for='reference-author-typeahead']",
                  /Author/
    assert_no_match "setUpReferenceAuthor", response.body
  end

  # Parent is on the shared stimulus-autocomplete markup too. The current
  # reference's id goes with every query so it is never offered as its own
  # parent, and the type is read from the Type select at query time.
  test "should render the parent field as a stimulus autocomplete" do
    sign_in_as_fake_user(
      username: "fred",
      full_name: "Fred Jones",
      groups: [ "edit" ]
    ) do
      get reference_tab_path(id: @reference.id, tab: "tab_edit_1"),
        headers: { "Accept" => "application/javascript" }
    end
    assert_response :success
    url = references_typeahead_on_citation_for_parent_path(format: :html)
    extra_params = { id: @reference.id }.to_json
    live_params = { ref_type_id: "reference_ref_type_id" }.to_json
    assert_select "div.autocomplete[data-controller='autocomplete']" \
      "[data-autocomplete-url-value='#{url}']" \
      "[data-autocomplete-extra-params-value='#{extra_params}']" \
      "[data-autocomplete-live-params-value='#{live_params}']" \
      "[data-autocomplete-term-delimiter-value='|'] " \
      "input#reference-parent-typeahead[data-autocomplete-target='input']" \
      "[name='reference[parent_typeahead]']",
                  true
    assert_select "div.autocomplete " \
      "input#reference_parent_id[data-autocomplete-target='hidden']",
                  true
    assert_select "div.autocomplete ul[data-autocomplete-target='results']",
                  true
    assert_select "div.autocomplete label[for='reference-parent-typeahead']",
                  /Parent/
    assert_select "p#current-ref-type-message-about-parent", true
    assert_no_match "setUpReferenceParent", response.body
  end
end
