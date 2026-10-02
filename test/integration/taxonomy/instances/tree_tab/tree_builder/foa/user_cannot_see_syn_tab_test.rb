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
class TaxoInstanceTreeBuilderFoaCannotSeeSynTab < ActionDispatch::IntegrationTest
  test "foa tree builder cannot see instance synonymy tab" do
    user = users(:foa_tax_builder)
    foa_draft = tree_versions(:foa_draft_version)
    instance = instances(:triodia_in_brassard)
    assert_routing "/instances/1/tab/tree",
                   controller: "instances",
                   action: "tab",
                   id: "1",
                   tab: "tree"

    sign_in_as_fake_user(
      username: user.user_name,
      full_name: user.full_name,
      groups: [ "login", "xedit" ],
      extra_session: { draft: { "id" => foa_draft.id } }
    ) do
      get instance_tab_path(id: instance.id, tab: "tab_synonymy"),
        xhr: true,
        headers: { "Accept" => "text/javascript" }
    end

    assert_response :forbidden, "Tree builder should not see Synonmy tab"
  end
end
