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

# Names::Typeaheads::ForWorkspaceParentNameController#index. Answers the
# shared html fragment to the tree workspace Parent fields, now on
# stimulus-autocomplete, offering names on the working draft.
class NameSuggsForWorkspaceParentNameTest < ActionDispatch::IntegrationTest
  setup do
    @draft = tree_versions(:apc_draft_version)
    @species = names(:angophora_costata)
    @genus_tve = place_in_draft(names(:angophora), "/tree/draft/genus")
    @family_tve = place_in_draft(names(:cyperaceae), "/tree/draft/family")
  end

  # No fixture puts anything on the draft, so each test places its own.
  def place_in_draft(name, element_link)
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
      instance: instances(:triodia_in_brassard),
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
      updated_at: Time.current,
      updated_by: "test",
    )
  end

  def get_suggestions(params, format: :html, groups: [ "edit", "treebuilder" ])
    sign_in_as_fake_user(
      username: "fred",
      full_name: "Fred Jones",
      groups: groups,
      extra_session: { draft: { "id" => @draft.id } }
    ) do
      get workspace_parent_name_suggestions_path(format: format),
        params: { name_id: @species.id }.merge(params)
    end
  end

  def assert_select_in_body(*args, &block)
    assert_select(Nokogiri::HTML::DocumentFragment.parse(response.body),
                  *args, &block)
  end

  # The label is what the library writes back into the input on a pick, and
  # the value is the parent's element link, not a record id.
  test "should offer ranks up to the next major one as an html fragment" do
    get_suggestions({ term: "Angoph" })

    assert_response :success
    assert_select_in_body(
      "li.autocomplete-result[data-autocomplete-value='#{@genus_tve.element_link}']" \
      "[data-autocomplete-label='#{names(:angophora).full_name} - Genus']" \
      "[data-excluded='false']",
      true
    )
  end

  test "should bold the matched part of the name" do
    get_suggestions({ term: "Angoph" })

    assert_includes response.body, "<strong>Angoph</strong>"
  end

  # Flagged for the ban icon, which the stylesheet draws. The label stays
  # plain text: it used to carry the icon's <i> tag into the input.
  test "should mark an excluded name and keep its label plain" do
    @genus_tve.tree_element.update_columns(excluded: true)

    get_suggestions({ term: "Angoph" })

    assert_response :success
    assert_select_in_body(
      "li.autocomplete-result[data-autocomplete-value='#{@genus_tve.element_link}']" \
      "[data-excluded='true']" \
      "[data-autocomplete-label='#{names(:angophora).full_name} - Genus']",
      true
    )
    assert_no_match "fa-ban", response.body
  end

  test "should leave out higher ranks unless asked for them" do
    get_suggestions({ term: "Cyper", allow_higher_ranks: "0" })

    assert_response :success
    assert_select_in_body(
      "li.autocomplete-result[data-autocomplete-value='#{@family_tve.element_link}']",
      false
    )
  end

  # The "Show higher ranks" box, sent as 1 when ticked.
  test "should offer higher ranks when asked for them" do
    get_suggestions({ term: "Cyper", allow_higher_ranks: "1" })

    assert_response :success
    assert_select_in_body(
      "li.autocomplete-result[data-autocomplete-value='#{@family_tve.element_link}']" \
      "[data-autocomplete-label='Cyperaceae - Familia']",
      true
    )
  end

  test "should mark an excluded higher rank name too" do
    @family_tve.tree_element.update_columns(excluded: true)

    get_suggestions({ term: "Cyper", allow_higher_ranks: "1" })

    assert_response :success
    assert_select_in_body(
      "li.autocomplete-result[data-autocomplete-value='#{@family_tve.element_link}']" \
      "[data-excluded='true']",
      true
    )
  end

  test "should render a no matches option for a blank term" do
    get_suggestions({ term: "" })

    assert_response :success
    assert_select_in_body "li.autocomplete-result[aria-disabled='true']",
                          text: "No matches"
  end

  test "should forbid a user who is not a treebuilder" do
    get_suggestions({ term: "Angoph" }, groups: [ "edit" ])

    assert_response :forbidden
    assert_no_match "autocomplete-result", response.body
  end

  # A 403, not a 500 from the nil draft.
  test "should forbid a treebuilder with no draft selected" do
    sign_in_as_fake_user(
      username: "fred",
      full_name: "Fred Jones",
      groups: [ "edit", "treebuilder" ]
    ) do
      get workspace_parent_name_suggestions_path(format: :html),
        params: { name_id: @species.id, term: "Angoph" }
    end

    assert_response :forbidden
    assert_no_match "autocomplete-result", response.body
  end

  test "should still answer json" do
    get_suggestions({ term: "Angoph" }, format: :json)

    assert_response :success
    assert_includes JSON.parse(response.body).pluck("id"), @genus_tve.element_link
  end

  # What the endpoint answered before html was added.
  test "should answer json to any other format" do
    sign_in_as_fake_user(
      username: "fred",
      full_name: "Fred Jones",
      groups: [ "edit", "treebuilder" ],
      extra_session: { draft: { "id" => @draft.id } }
    ) do
      get workspace_parent_name_suggestions_path,
        params: { name_id: @species.id, term: "Angoph" },
        headers: { "Accept" => "application/javascript" }
    end

    assert_response :success
    assert_includes JSON.parse(response.body).pluck("id"), @genus_tve.element_link
  end
end
