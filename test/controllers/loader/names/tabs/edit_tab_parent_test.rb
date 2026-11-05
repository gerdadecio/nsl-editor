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

# The loader name synonym and misapplied edit forms' Parent field is on the
# shared stimulus-autocomplete markup, not typeahead.js.
class LoaderNameEditTabParentTest < ActionDispatch::IntegrationTest
  def get_tab(loader_name, tab)
    sign_in_as_fake_user(groups: [ "batch-loader" ]) do
      get loader_name_tab_path(id: loader_name.id, tab: tab),
        headers: { "Accept" => "application/javascript" }
    end
    assert_response :success
  end

  def assert_parent_autocomplete(loader_name)
    url = loader_names_parent_suggestions_path(format: :html)
    parent = loader_name.parent
    assert_select "div.autocomplete[data-controller='autocomplete']" \
      "[data-autocomplete-url-value='#{url}'] " \
      "input#loader-name-parent-typeahead[data-autocomplete-target='input']" \
      "[name='loader_name[parent_typeahead]']" \
      "[value='#{parent.simple_name}']",
                  true
    assert_select "div.autocomplete[data-autocomplete-extra-params-value=?]",
                  { loader_batch_id: loader_name.loader_batch_id, avoid_id: loader_name.id }.to_json
    assert_select "div.autocomplete " \
      "input#loader_name_parent_id[data-autocomplete-target='hidden']" \
      "[value='#{parent.id}']",
                  true
    # Rendered once in the edit form, by the partial. (The tab's convert
    # form carries its own hidden parent_id.)
    assert_select "form:has(#loader-name-save) input#loader_name_parent_id", count: 1
    assert_select "div.autocomplete label[for='loader-name-parent-typeahead']", /Parent/
    assert_no_match "setUpLoaderNameParentTypeahead", response.body
  end

  test "should render the synonym form's parent field as a stimulus autocomplete" do
    loader_name = loader_names(:synonym_guards_pass)
    get_tab(loader_name, "tab_edit")
    assert_parent_autocomplete(loader_name)
  end

  test "should render the misapplied form's parent field as a stimulus autocomplete" do
    loader_name = loader_names(:misapp_guards_pass)
    get_tab(loader_name, "tab_edit")
    assert_parent_autocomplete(loader_name)
  end

  # A new synonym has no Parent field: its parent is the accepted record,
  # carried in a plain hidden parent_id.
  test "should keep the create synonym form's hidden parent id" do
    accepted = loader_names(:zzz_test_parent_with_match)
    get_tab(accepted, "tab_create_syn")

    assert_select "input#loader-name-parent-typeahead", false
    assert_select "input#loader_name_parent_id[type='hidden'][value='#{accepted.id}']", true
  end
end
