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

# The workspace Parent fields empty the hidden parent_element_link whenever
# the user types, and fill it only when a suggestion is picked. Parent text
# with no link means nothing was picked, so place, replace and update parent
# all refuse it before calling Services. WebMock would fail any call that
# got through, since none is stubbed here.
class TreeParentNotPickedTest < ActionDispatch::IntegrationTest
  setup do
    @draft = tree_versions(:apc_draft_version)
    @instance = instances(:usage_of_name_to_be_placed)
  end

  def post_as_treebuilder(path, params)
    sign_in_as_fake_user(
      username: "fred",
      full_name: "Fred Jones",
      groups: [ "edit", "treebuilder" ],
      extra_session: { draft: { "id" => @draft.id } }
    ) do
      post path, params: params,
                 headers: { "Accept" => "application/javascript" }
    end
  end

  def assert_refused(error_container)
    assert_response :unprocessable_content
    assert_includes response.body, error_container
    assert_includes response.body, TreesController::PARENT_NOT_PICKED_MESSAGE
  end

  test "should refuse to place a name with parent text but no picked parent" do
    post_as_treebuilder(
      tree_place_name_path(id: @draft.id),
      { place_name: { instance_id: @instance.id,
                      version_id: @draft.id,
                      parent_name_typeahead_string: "Angoph",
                      parent_element_link: "", } }
    )

    assert_refused "#placement-error-message-container"
  end

  test "should refuse to replace with parent text but no picked parent" do
    post_as_treebuilder(
      tree_replace_placement_path(id: @draft.id),
      { move_placement: { element_link: "/tree/draft/anything",
                          instance_id: @instance.id,
                          parent_name_typeahead_string: "Angoph",
                          parent_element_link: "", } }
    )

    assert_refused "#movement-error-message"
  end

  test "should refuse to update a parent with parent text but no picked parent" do
    post_as_treebuilder(
      tree_update_parent_path,
      { update_parent: { element_link: "/tree/draft/anything",
                         version_id: @draft.id,
                         parent_name_typeahead_string: "Angoph",
                         parent_element_link: "", } }
    )

    assert_refused "#movement-error-message"
  end
end
