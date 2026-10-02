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
class TaxFormsTreePublisherAPCUserCannotUpdateTreeParentForTaxonOnAPCDraftTest < ActionDispatch::IntegrationTest
  test "APC tree publisher user cannot update tree parent of taxon on APC draft" do
    user = users(:apc_tax_publisher)
    apc_draft = tree_versions(:apc_draft_version)
    tve = tree_version_elements(:tve_for_red_gum)

    sign_in_as_fake_user(
      username: user.user_name,
      full_name: user.full_name,
      groups: [ "login" ],
      extra_session: { draft: { "id" => apc_draft.id } }
    ) do
      post tree_update_parent_path,
        params: {
          "update_parent" => {
            "element_link" => tve.element_link,
            "parent_name_typeahead_string" => "Sersalisia R.Br. - Genus",
            "parent_element_link" => "/tree/52410590/51363635",
            "version_id" => apc_draft.id,
            "update" => "",
          },
        },
        xhr: true,
        headers: { "Accept" => "text/javascript" }
    end

    assert_response :forbidden, "APC tree publisher should not be able to update tree parent of taxon on APC"
    assert_match(
      /Access Denied\! Please contact the admin for proper permissions/,
      response.body,
      "Expecting Access Denied message"
    )
  end
end
