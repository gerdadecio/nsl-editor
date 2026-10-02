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

# Single search controller test.
#
# Note:
#   xhr: true
#
# stopped this error in test:
#
# ActionController::InvalidCrossOriginRequest: Security warning:
#   an embedded <script> tag on another site requested protected JavaScript.
class TaxFormsUserWithNoRoleCannotReplacePlacementOnAPCDraftTest < ActionDispatch::IntegrationTest
  # Example of a real request this action receives (from server logs), for
  # reference - id and instance_id below are this test's own fixture values,
  # not the ones shown here:
  #
  # r6editor Started PATCH "/nsl/editor/trees/:id/replace_placement"
  # r6editor Processing by TreesController#replace_placement as JS
  # Parameters: {"authenticity_token"=>"[FILTERED]",
  #             "move_placement"=>{"element_link"=>"/tree/52410589/52410631",
  #                                "instance_id"=>"612279",
  #                                "comment"=>"Subspecies are recognised in this species in Euclid... ",
  #                                "parent_name_typeahead_string"=>"Angophora Cav.",
  #                                "parent_element_link"=>"/tree/52410589/51230780",
  #                                "update"=>""},
  #            "id"=>"612279"}
  test "user with no role cannot replace placement for taxon on APC tree draft" do
    user = users(:no_role)
    apc_draft = tree_versions(:apc_draft_version)
    tve = tree_version_elements(:tve_for_red_gum)

    sign_in_as_fake_user(
      username: user.user_name,
      full_name: user.full_name,
      groups: [ "login" ],
      extra_session: { draft: { "id" => apc_draft.id } }
    ) do
      patch tree_replace_placement_path(id: tve.id),
        params: {
          "move_placement" => {
            "element_link" => tve.element_link,
            "instance_id" => tve.id,
            "comment" => "xyz comment",
            "parent_name_typeahead_string" => "Angophora Cav.",
            "parent_element_link" => tve.element_link,
            "update" => "",
          },
        },
        xhr: true,
        headers: { "Accept" => "text/javascript" }
    end

    assert_response :forbidden, "APC tree publisher should be not able to replace_placement on APC draft entry"
    assert_match "Access Denied", response.body, "Expecting Access Denied message"
  end
end
