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

  # Base Author is the second field moved onto the shared partial.
  test "should render the base author field as a stimulus autocomplete" do
    @request.headers["Accept"] = "application/javascript"
    get(:show,
        params: { id: @name.id, tab: "tab_edit" },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: ["edit"] })
    assert_response :success
    assert_select "div.autocomplete[data-controller='autocomplete']" \
                  " input#base-author-by-abbrev" \
                  "[data-autocomplete-target='input']",
                  true
    assert_select "div.autocomplete" \
                  " input#name_base_author_id" \
                  "[data-autocomplete-target='hidden']",
                  true
    assert_select "div.autocomplete label[for='base-author-by-abbrev']",
                  "Base Name Author"
  end

  # Ex Author is the third field moved onto the shared partial.
  test "should render the ex author field as a stimulus autocomplete" do
    @request.headers["Accept"] = "application/javascript"
    get(:show,
        params: { id: @name.id, tab: "tab_edit" },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: ["edit"] })
    assert_response :success
    assert_select "div.autocomplete[data-controller='autocomplete']" \
                  " input#ex-author-by-abbrev" \
                  "[data-autocomplete-target='input']",
                  true
    assert_select "div.autocomplete" \
                  " input#name_ex_author_id" \
                  "[data-autocomplete-target='hidden']",
                  true
    assert_select "div.autocomplete label[for='ex-author-by-abbrev']",
                  "Ex Author"
  end

  # Ex Base Author is the fourth field moved onto the shared partial.
  test "should render the ex base author field as a stimulus autocomplete" do
    @request.headers["Accept"] = "application/javascript"
    get(:show,
        params: { id: @name.id, tab: "tab_edit" },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: ["edit"] })
    assert_response :success
    assert_select "div.autocomplete[data-controller='autocomplete']" \
                  " input#ex-base-author-by-abbrev" \
                  "[data-autocomplete-target='input']",
                  true
    assert_select "div.autocomplete" \
                  " input#name_ex_base_author_id" \
                  "[data-autocomplete-target='hidden']",
                  true
    assert_select "div.autocomplete label[for='ex-base-author-by-abbrev']",
                  "Ex Base Name Author"
  end

  # Sanctioning Author is the fifth and last field moved onto the shared
  # partial.
  test "should render the sanctioning author field as a stimulus autocomplete" do
    @request.headers["Accept"] = "application/javascript"
    get(:show,
        params: { id: @name.id, tab: "tab_edit" },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: ["edit"] })
    assert_response :success
    assert_select "div.autocomplete[data-controller='autocomplete']" \
                  " input#sanctioning-author-by-abbrev" \
                  "[data-autocomplete-target='input']",
                  true
    assert_select "div.autocomplete" \
                  " input#name_sanctioning_author_id" \
                  "[data-autocomplete-target='hidden']",
                  true
    assert_select "div.autocomplete label[for='sanctioning-author-by-abbrev']",
                  "Sanctioning Author"
  end

  # The name form's first Parent field, off typeahead.js and onto the same
  # shared markup as the author fields.
  test "should render the parent field as a stimulus autocomplete" do
    @request.headers["Accept"] = "application/javascript"
    get(:show,
        params: { id: @name.id, tab: "tab_edit" },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: ["edit"] })
    assert_response :success
    assert_select "div.autocomplete[data-controller='autocomplete']" \
                  " input#name-parent-typeahead" \
                  "[data-autocomplete-target='input']",
                  true
    assert_select "div.autocomplete" \
                  " input#name_parent_id" \
                  "[data-autocomplete-target='hidden']",
                  true
    assert_select "div.autocomplete label[for='name-parent-typeahead']",
                  "Parent*"
    assert_no_match(/setUpNameParentTypeahead\(\)/, @response.body)
    assert_no_match(/setUpNameHybridParentTypeahead\(\)/, @response.body)
    assert_no_match(/setUpNameCultivarParentTypeahead\(\)/, @response.body)
  end

  # The rank the parent suggestions are restricted by can be changed without
  # leaving the form, so it is read from the select at query time rather
  # than baked into the field when it renders - see the autocomplete
  # controller's liveParams. The name's own id can be baked in.
  test "should have the parent field read the rank live" do
    @request.headers["Accept"] = "application/javascript"
    get(:show,
        params: { id: @name.id, tab: "tab_edit" },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: ["edit"] })
    assert_response :success
    field = css_select("div.autocomplete").find do |div|
      div.css("input#name-parent-typeahead").any?
    end
    assert_equal({ "rank_id" => "name_name_rank_id" },
                 JSON.parse(field["data-autocomplete-live-params-value"]))
    assert_equal({ "name_id" => @name.id },
                 JSON.parse(field["data-autocomplete-extra-params-value"]))
    assert_equal "|", field["data-autocomplete-term-delimiter-value"]
  end

  # With Sanctioning Author across, no author field asks for the old
  # typeahead.js set-up any more.
  test "should leave no author field on the legacy typeahead" do
    @request.headers["Accept"] = "application/javascript"
    get(:show,
        params: { id: @name.id, tab: "tab_edit" },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: ["edit"] })
    assert_response :success
    assert_no_match(/setUpAuthorByAbbrev\(\)/, @response.body)
    assert_no_match(/setUpBaseAuthorByAbbrev\(\)/, @response.body)
    assert_no_match(/setUpExAuthorByAbbrev\(\)/, @response.body)
    assert_no_match(/setUpExBaseAuthorByAbbrev\(\)/, @response.body)
    assert_no_match(/setUpSanctioningAuthorByAbbrev\(\)/, @response.body)
  end
end
