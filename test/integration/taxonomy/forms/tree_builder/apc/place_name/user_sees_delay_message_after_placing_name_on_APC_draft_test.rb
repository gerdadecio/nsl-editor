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
#
# Note:
#   xhr: true
#
# stopped this error in test:
#
# ActionController::InvalidCrossOriginRequest: Security warning:
#   an embedded <script> tag on another site requested protected JavaScript.
#
# The sibling test in this directory stops at the first API call. This one
# stubs the whole conversation so the place_name view actually renders, which
# is where the user is told the change may be delayed.
class TaxFormsTreeBuilderAPCUserSeesDelayMessageAfterPlacingNameOnAPCDraftTest < ActionController::TestCase
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

    # Second call: the actual placeElement request, using the link from the first call.
    stub_request(:put, %r{http:..localhost:909..nsl.services.api.treeElement.placeElement.apiKey=.*.as=apc-tax-builder}).
      with(
        headers: {
          'Accept'=>/json/,
          'Accept-Encoding'=>/.*/,
          'Content-Type'=>/json/,
          'Host'=>/localhost/,
          'User-Agent'=>/ruby/
        }).
      to_return(status: 200,
                body: { ok: true, payload: { message: "Placed on the draft" } }.to_json,
                headers: {})
  end

  test "APC tree builder user is told a placement may be delayed" do
    user = users(:apc_tax_builder)
    apc_draft = tree_versions(:apc_draft_version)
    tve = tree_version_elements(:tve_for_red_gum)
    post(:place_name,
         params: {"place_name"=>{"instance_id"=>12345,
                                 "comment"=>"blah",
                                 "distribution"=>["NSW"],
                                 "parent_name_typeahead_string"=>"Angophora bakeri E.C.Hall",
                                 "parent_element_link"=>tve.element_link,
                                 "version_id"=>apc_draft.id,
                                 "place"=>""},
                  "id" => tve.id
                 },
         format: :js,
         xhr: true,
         session: { username: user.user_name,
                    user_full_name: user.full_name,
                    draft: apc_draft,
                    groups: ["login"]})
    assert_response :success, 'APC tree builder should be able to place a name on APC draft'
    assert_template "place_name"
    assert_includes @response.body, "Placed on the draft",
                    'Placing should report what the services said'
    # The services queue the change, so the user is told it may lag.
    assert_includes @response.body, TreesHelper::TREE_CHANGE_DELAY_MESSAGE,
                    'Placing should warn that the change may be delayed'
  end
end
