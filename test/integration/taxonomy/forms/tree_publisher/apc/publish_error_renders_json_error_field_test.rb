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

# When the publish service returns a non-ok response that includes an
# "error" field, the controller should use that field as @message rather
# than calling the undefined json_result method (which was the pre-fix
# behaviour and caused a NoMethodError).
class TaxFormsTreePubAPCPublishErrorRendersJsonErrorFieldTest < ActionDispatch::IntegrationTest
  def setup
    stub_request(:put, /http:..localhost:90...nsl.services.api.treeVersion.publish.apiKey=test-api-key.as=apc-tax-publisher/)
      .to_return(status: 200,
                 body: '{"ok":false,"error":"Publishing service unavailable"}',
                 headers: { "Content-Type" => "application/json" })
  end

  test "publish failure renders the error field from the JSON response" do
    user = users(:apc_tax_publisher)
    apc_draft = tree_versions(:apc_draft_version)

    sign_in_as_fake_user(
      username: user.user_name,
      full_name: user.full_name,
      groups: ["login"],
      extra_session: { draft: { "id" => apc_draft.id } }
    ) do
      post tree_versions_publish_path,
        params: {
          "version_id" => apc_draft.id,
          "next_draft_name" => "next draft",
          "draft_log" => "log entry",
        },
        xhr: true,
        headers: { "Accept" => "text/javascript" }
    end

    assert_response :success
    assert_match "Publishing service unavailable", response.body
  end
end
