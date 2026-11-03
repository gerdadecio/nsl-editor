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

# The classification tab's Parent field, on the shared stimulus-autocomplete
# markup (app/views/shared/_autocomplete_field) rather than typeahead.js, in
# each of the tab's three forms: place, update parent and replace.
class InstClassificationTabParentFieldTest < ActionDispatch::IntegrationTest
  setup do
    @instance = instances(:triodia_in_brassard)
    @draft = tree_versions(:apc_draft_version)
  end

  # No fixture puts anything on the draft, so each test places its own.
  # The element's instance needn't be of the name: the tab only compares it
  # with the instance shown, to choose between update parent and replace.
  def place_in_draft(name, instance, element_link, parent: nil)
    element = Tree::Element.create!(
      display_html: "<data></data>",
      excluded: false,
      instance_link: "ilink#{element_link}",
      name_element: name.simple_name,
      name_link: "nlink#{element_link}",
      rank: name.name_rank.name,
      simple_name: name.simple_name,
      source_shard: "APNI",
      synonyms_html: "<synonyms></synonyms>",
      updated_by: "test",
      updated_at: Time.current,
      instance: instance,
      name: name,
    )
    TreeVersionElement.create!(
      element_link: element_link,
      depth: 1,
      name_path: name.simple_name,
      taxon_id: element.id,
      taxon_link: "/node/apni/#{element.id}",
      tree_element: element,
      tree_path: "/#{element.id}",
      tree_version: @draft,
      parent_id: parent&.element_link,
      updated_at: Time.current,
      updated_by: "test",
    )
  end

  def get_classification_tab
    sign_in_as_fake_user(
      username: "fred",
      full_name: "Fred Jones",
      groups: [ "edit", "treebuilder" ],
      extra_session: { draft: { "id" => @draft.id } }
    ) do
      get instance_tab_path(id: @instance.id, tab: "tab_classification",
                            "row-type": "instance_record"),
        headers: { "Accept" => "application/javascript" }
    end
  end

  def assert_parent_field(param_key, parent_element_link: nil)
    url = workspace_parent_name_suggestions_path(format: :html)
    extra_params = { name_id: @instance.name.id,
                     parent_element_id: parent_element_link, }.to_json
    live_params = { allow_higher_ranks: "allow_higher_ranks" }.to_json
    assert_select "div.autocomplete[data-controller='autocomplete']" \
      "[data-autocomplete-url-value='#{url}']" \
      "[data-autocomplete-extra-params-value='#{extra_params}']" \
      "[data-autocomplete-live-params-value='#{live_params}']" \
      "[data-autocomplete-term-delimiter-value=' -'] " \
      "input#workspace_parent_name_typeahead[data-autocomplete-target='input']" \
      "[name='#{param_key}[parent_name_typeahead_string]']",
                  true
    hidden = "div.autocomplete " \
      "input#workspace_parent_name_id[type='hidden'][data-autocomplete-target='hidden']" \
      "[name='#{param_key}[parent_element_link]']"
    hidden += "[value='#{parent_element_link}']" if parent_element_link
    assert_select hidden, true
    assert_select "div.autocomplete ul[data-autocomplete-target='results']",
                  true
    assert_select "input#allow_higher_ranks[type='checkbox']", true
    assert_no_match "setUpWorkspaceParentName", response.body
  end

  test "should render the place form's parent field as a stimulus autocomplete" do
    get_classification_tab

    assert_response :success
    assert_select "form", true
    assert_parent_field("place_name")
    assert_select "input#workspace_id[name='place_name[version_id]'][value='#{@draft.id}']",
                  true
  end

  # The instance is on the draft, so the tab offers its Update parent form,
  # filled in with its current parent.
  test "should render the update parent field as a stimulus autocomplete" do
    parent_name = names(:angophora)
    parent = place_in_draft(parent_name, @instance, "/tree/draft/parent")
    place_in_draft(@instance.name, @instance, "/tree/draft/triodia", parent: parent)

    get_classification_tab

    assert_response :success
    assert_parent_field("update_parent", parent_element_link: parent.element_link)
    assert_select "input#workspace_parent_name_typeahead[value='#{parent_name.full_name}']",
                  true
    assert_select "input#workspace_id[name='update_parent[version_id]'][value='#{@draft.id}']",
                  true
  end

  # Another instance of the name is on the draft, so the tab offers to
  # replace it.
  test "should render the replace form's parent field as a stimulus autocomplete" do
    place_in_draft(@instance.name, instances(:britten_created_angophora_costata), "/tree/draft/triodia")

    get_classification_tab

    assert_response :success
    assert_parent_field("move_placement")
    assert_select "input#workspace_parent_name_typeahead[required]", true
  end
end
