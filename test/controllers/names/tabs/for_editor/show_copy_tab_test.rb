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
class NameShowCopyTabForEditorTest < ActionDispatch::IntegrationTest
  setup do
    @name = names(:a_species)
  end

  test "should show copy tab" do
    sign_in_as_fake_user(
      username: "fred",
      full_name: "Fred Jones",
      groups: [ "edit" ]
    ) do
      get name_tab_path(id: @name.id, tab: "tab_copy"),
        headers: { "Accept" => "application/javascript" }
    end
    assert_response :success
    assert_select "li.active a#name-copy-tab",
                  "Copy",
                  "Should show 'Copy' tab."
  end

  # Copying a hybrid is the one place outside the edit form that renders the
  # Parent field, and a hybrid takes its parents from their own endpoint -
  # what setUpNameHybridParentTypeahead used to wire up.
  test "should show the parent field on the copy tab of a hybrid" do
    sign_in_as_fake_user(
      username: "fred",
      full_name: "Fred Jones",
      groups: [ "edit" ]
    ) do
      get name_tab_path(id: names(:hybrid_formula).id, tab: "tab_copy"),
        headers: { "Accept" => "application/javascript" }
    end
    assert_response :success
    assert_select "div.autocomplete[data-controller='autocomplete']" \
      "[data-autocomplete-url-value=" \
      "'/suggestions/name/hybrid_parent.html'] " \
      "input#name-parent-typeahead" \
      "[data-autocomplete-target='input']",
                  true
    assert_select "div.autocomplete input#name_parent_id" \
      "[data-autocomplete-target='hidden']",
                  true
  end

  # The copy form's Second parent is the same shared field, so the
  # copy-name-form controller can watch both parents through the one pair
  # of bubbling events.
  test "should show the second parent field on the copy tab of a hybrid" do
    hybrid = names(:hybrid_formula)
    sign_in_as_fake_user(
      username: "fred",
      full_name: "Fred Jones",
      groups: [ "edit" ]
    ) do
      get name_tab_path(id: hybrid.id, tab: "tab_copy"),
        headers: { "Accept" => "application/javascript" }
    end
    assert_response :success
    assert_select "div.autocomplete[data-controller='autocomplete']" \
      "[data-autocomplete-url-value=" \
      "'/suggestions/name/hybrid_parent.html'] " \
      "input#name-second-parent-typeahead" \
      "[data-autocomplete-target='input']" \
      "[value='#{hybrid.second_parent.full_name}']",
                  true
    assert_select "div.autocomplete input#name_second_parent_id" \
      "[data-autocomplete-target='hidden']" \
      "[value='#{hybrid.second_parent_id}']",
                  true
    assert_no_match(/setUpNameSecondParentTypeahead\(\)/, response.body)
  end

  # A cultivar hybrid's copy form takes both parents from the
  # cultivar-scoped endpoint, its Second parent in place of
  # setUpNameCultivarSecondParentTypeahead.
  test "should show the second parent field on the copy tab of a cultivar hybrid" do
    cultivar_hybrid = names(:a_cultivar_hybrid)
    sign_in_as_fake_user(
      username: "fred",
      full_name: "Fred Jones",
      groups: [ "edit" ]
    ) do
      get name_tab_path(id: cultivar_hybrid.id, tab: "tab_copy"),
        headers: { "Accept" => "application/javascript" }
    end
    assert_response :success
    assert_select "div.autocomplete[data-controller='autocomplete']" \
      "[data-autocomplete-url-value=" \
      "'/suggestions/name/cultivar_parent.html'] " \
      "input#name-second-parent-typeahead" \
      "[data-autocomplete-target='input']" \
      "[value='#{cultivar_hybrid.second_parent.full_name}']",
                  true
    assert_select "div.autocomplete input#name_second_parent_id" \
      "[data-autocomplete-target='hidden']" \
      "[value='#{cultivar_hybrid.second_parent_id}']",
                  true
    assert_no_match(
      /setUpNameCultivarSecondParentTypeahead\(\)/,
      response.body
    )
  end

  # The copy standalone instances form's Target Name field is on
  # stimulus-autocomplete, asking the full name endpoint for html, with the
  # dom ids and param name the copy action reads unchanged.
  test "should render the copy instances target name field as a stimulus autocomplete" do
    name = names(:angophora_costata)
    sign_in_as_fake_user(
      username: "fred",
      full_name: "Fred Jones",
      groups: [ "edit" ]
    ) do
      get name_tab_path(id: name.id, tab: "tab_copy"),
        headers: { "Accept" => "application/javascript" }
    end
    assert_response :success
    assert_select "div.autocomplete[data-controller='autocomplete']" \
      "[data-autocomplete-url-value='/names/typeahead_on_full_name.html']" \
      "[data-autocomplete-term-delimiter-value=' - '] " \
      "input#instance-target-name-typeahead" \
      "[data-autocomplete-target='input'][required]",
                  true
    assert_select "label[for='instance-target-name-typeahead']", /Target Name/
    # The hidden target_name_id starts empty and is rendered once, by the
    # partial, so the copy action still asks for a target until a pick.
    assert_select "div.autocomplete input#name_target_name_id" \
      "[name='name[target_name_id]']" \
      "[data-autocomplete-target='hidden'][value='']",
                  true
    assert_select "input#name_target_name_id", count: 1
    assert_no_match(/setUpInstancesTargetName\(\)/, response.body)
  end
end
