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
class ShowEditTest < ActionController::TestCase
  tests NamesController
  setup do
    @name = names(:a_species)
  end

  test "should show name edit tab" do
    @request.headers["Accept"] = "application/javascript"
    get(:show,
        params: { id: @name.id, tab: "tab_edit" },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: ["edit"] })
    assert_response :success
    assert_select "li.active a#name-edit-tab", "Edit", "Should show 'Edit' tab."
    assert_select "form", true
    assert_select "select#name_name_type_id", true
    assert_select "select#name_name_status_id", true
    assert_select "select#name_name_rank_id", true
    assert_select "input#name_author_id", true
    assert_select "input#name_base_author_id", true
    assert_select "input#name_ex_base_author_id", true
    assert_select "input#name_ex_author_id", true
    assert_select "input#name_sanctioning_author_id", true
  end

  # The Author field is the first migrated off typeahead.js onto the shared
  # stimulus-autocomplete markup (app/views/shared/_autocomplete_field).
  test "should render the author field as a stimulus autocomplete" do
    @request.headers["Accept"] = "application/javascript"
    get(:show,
        params: { id: @name.id, tab: "tab_edit" },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: ["edit"] })
    assert_response :success
    assert_select "div.autocomplete[data-controller='autocomplete']" \
                  " input#author-by-abbrev[data-autocomplete-target='input']",
                  true
    assert_select "div.autocomplete" \
                  " input#name_author_id[data-autocomplete-target='hidden']",
                  true
    assert_select "div.autocomplete ul[data-autocomplete-target='results']",
                  true
    assert_select "div.autocomplete label[for='author-by-abbrev']", "Author"
  end

  # The other four author fields have not been migrated, so they must still
  # render the plain typeahead.js markup and its inline set-up call.
  test "should leave the other author fields on the legacy typeahead" do
    @request.headers["Accept"] = "application/javascript"
    get(:show,
        params: { id: @name.id, tab: "tab_edit" },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: ["edit"] })
    assert_response :success
    assert_select "div.autocomplete input#base-author-by-abbrev", false
    assert_select "input#base-author-by-abbrev", true
    assert_no_match(/setUpAuthorByAbbrev\(\)/, @response.body)
    assert_match(/setUpBaseAuthorByAbbrev\(\)/, @response.body)
  end
end
