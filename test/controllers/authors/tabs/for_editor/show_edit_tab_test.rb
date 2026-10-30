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

# Single controller test.
class AuthorEditorShowEditTest < ActionDispatch::IntegrationTest
  setup do
    @author = authors(:bentham)
  end

  test "should show editor author edit tab" do
    sign_in_as_fake_user(
      username: "fred",
      full_name: "Fred Jones",
      groups: [ "edit" ]
    ) do
      get author_tab_path(id: @author.id, tab: "tab_edit"),
        headers: { "Accept" => "application/javascript" }
    end
    assert_select "li.active a#author-edit-tab",
                  "Edit",
                  "Should show 'Edit' tab."
    assert_select "form", true
    assert_select "input#author_name", true
    assert_select "input#author_abbrev", true
    assert_select "input#author_extra_information", true
    assert_select "textarea#author_notes", true
    assert_select "input#author_duplicate_of_id", true
  end

  # Duplicate of is on the shared stimulus-autocomplete markup
  # (app/views/shared/_autocomplete_field), not typeahead.js.
  test "should render the duplicate of field as a stimulus autocomplete" do
    sign_in_as_fake_user(
      username: "fred",
      full_name: "Fred Jones",
      groups: [ "edit" ]
    ) do
      get author_tab_path(id: @author.id, tab: "tab_edit"),
        headers: { "Accept" => "application/javascript" }
    end
    assert_response :success
    url = authors_typeahead_on_name_duplicate_of_current_path(id: @author.id, format: :html)
    assert_select "div.autocomplete[data-controller='autocomplete']" \
      "[data-autocomplete-url-value='#{url}']" \
      "[data-autocomplete-term-delimiter-value='|'] " \
      "input#author-duplicate-of-typeahead[data-autocomplete-target='input']" \
      "[name='author[duplicate_of_typeahead]']",
                  true
    assert_select "div.autocomplete " \
      "input#author_duplicate_of_id[data-autocomplete-target='hidden']",
                  true
    assert_select "div.autocomplete ul[data-autocomplete-target='results']",
                  true
    assert_select "div.autocomplete label[for='author-duplicate-of-typeahead']",
                  "Duplicate of"
    assert_no_match "setUpAuthorDuplicateOfTypeahead", response.body
  end
end
