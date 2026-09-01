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
class TaxFormsTreeBuilderAPCUserCanReplacePlacementOnAPCDraftTest < ActionController::TestCase
  tests TreesController

  def setup
    # First call: look up the instance's preferred link, needed to build the
    # second call's payload.
    stub_request(:get, %r{http:..localhost:90...*broker.preferredLink.idNumber=12345.nameSpace=anamespace.objectType=instance}).
    with(
      headers: {
       'Accept'=>/json/,
       'Accept-Encoding'=>/.*/,
       'Content-Type'=>/json/,
       'Host'=>/localhost/,
       'User-Agent'=>/ruby/
       }).
       to_return(status: 200, body: { link: "http://localhost:9091/nsl/instance/apni/12345" }.to_json, headers: {})

    # Second call: the actual replaceElement request, using the link from the first call.
    stub_request(:put, %r{http:..localhost:909..nsl.services.api.treeElement.replaceElement.apiKey=.*.as=apc-tax-builder}).
    with(
      headers: {
       'Accept'=>/json/,
       'Accept-Encoding'=>/.*/,
       'Content-Type'=>/json/,
       'Host'=>/localhost/,
       'User-Agent'=>/ruby/
       }).
       to_return(status: 200, body: { ok: true, payload: {} }.to_json, headers: {})
  end

# r6editor Started PATCH "/nsl/editor/trees/612279/replace_placement" for ::1 at 2025-07-17 15:34:26 +1000 (pid:642)
# r6editor Processing by TreesController#replace_placement as JS (pid:642)
# Parameters: {"authenticity_token"=>"[FILTERED]",
 #             "move_placement"=>{"element_link"=>"/tree/52410589/52410631",
 #                                "instance_id"=>"612279",
 #                                "comment"=>"Subspecies are recognised in this species in Euclid... ",
 #                                "parent_name_typeahead_string"=>"Angophora Cav.",
 #                                "parent_element_link"=>"/tree/52410589/51230780",
 #                                "update"=>""},
 #            "id"=>"612279"}
  test "APC tree builder user can replace placement for taxon on APC tree draft" do
    user = users(:apc_tax_builder)
    apc_draft = tree_versions(:apc_draft_version)
    tve = tree_version_elements(:tve_for_red_gum)
    # The replace_placement is complex with one API call (preferredLink) providing
    # params for a second API call (replaceElement) - both are stubbed in setup.
    patch(:replace_placement,
         params: {"move_placement"=>{"element_link"=>tve.element_link,
                                     "instance_id"=>"12345",
                                     "comment"=>"xyz comment",
                                     "parent_name_typeahead_string"=>"Angophora Cav.",
                                     "parent_element_link"=> tve.element_link,
                                     "update"=>""},
                   "id"=>"612279"},
         format: :js,
         xhr: true,
         session: { username: user.user_name,
                    user_full_name: user.full_name,
                    draft: apc_draft,
                    groups: ["login"]})
    assert_response :success, 'APC tree builder should be able to replace_placement on APC draft entry'
    assert_template "moved_placement"
    # The services queue the change, so the user is told it may lag and is
    # given a refresh button instead of the tab reloading straight onto data
    # that has not caught up yet.
    assert_includes @response.body, TreesHelper::TREE_CHANGE_DELAY_MESSAGE,
                    'Replacing should warn that the change may be delayed'
    assert_includes @response.body, 'refreshTreeTab',
                    'Replacing should offer a refresh button'
    refute_includes @response.body, "$('#instance-classification-tab').click()",
                    'Replacing should not reload the tree tab immediately'
  end
end

