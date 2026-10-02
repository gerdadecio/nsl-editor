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

# Comments controller tests.
class WorkspaceCurrentToggleOffTest < ActionDispatch::IntegrationTest
  setup do
    @tree = tree_versions(:apc_draft_version)
  end

  test "toggle workspace off" do
    sign_in_as_fake_user(
      username: "fred",
      full_name: "Fred Jones",
      groups: [ "edit", "treebuilder" ],
      extra_session: { draft: { "id" => @tree.id } }
    ) do
      post toggle_current_workspace_path,
        params: { id: @tree.id },
        headers: { "Accept" => "application/javascript" }
    end

    assert_response :success
    assert_not session["draft"].present?
  end
end
