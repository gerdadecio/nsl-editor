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

# A timeout has no response body, so json_error falls back to the
# exception's message instead of failing to parse the body.
class APCTreeBuilderSynonymyReportTimeoutTest < ActionDispatch::IntegrationTest
  setup do
    stub_request(:get, /tree.checkCurrentSynonymy/).to_timeout
  end

  test "a timed out syn report shows the timeout as the error" do
    user = users(:apc_tax_builder)
    draft = tree_versions(:apc_draft_version)

    sign_in_as_fake_user(
      username: user.user_name,
      full_name: user.full_name,
      groups: [ "login" ],
      extra_session: { draft: { "id" => draft.id } }
    ) do
      get run_cas_path,
        xhr: true,
        headers: { "Accept" => "text/javascript" }
    end

    assert_response :success
    assert_match "Error running cas: Timed out", response.body
  end
end
