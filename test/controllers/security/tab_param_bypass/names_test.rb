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

# See references_test.rb in this folder. A reader is granted
# can("names", "tab_details").
class TabParamBypassNamesTest < ActionDispatch::IntegrationTest
  setup do
    @name = names(:a_genus)
    stub_request(:any, /localhost:9090/).to_return(status: 200, body: "{}")
  end

  test "reader cannot update a name by adding a permitted tab param" do
    original_element = @name.name_element
    sign_in_as_fake_user(username: "fred", full_name: "Fred Jones", groups: []) do
      patch name_path(id: @name.id, tab: "tab_details"),
        params: { name: { name_element: "changedbyreader" } },
        headers: { "Accept" => "application/javascript" },
        xhr: true
    end
    assert_response :forbidden
    assert_equal original_element, @name.reload.name_element
  end

  test "reader cannot create a name by adding a permitted tab param" do
    assert_no_difference("Name.count") do
      sign_in_as_fake_user(username: "fred", full_name: "Fred Jones", groups: []) do
        post names_path(tab: "tab_details"),
          params: {
            name: {
              "name_status_id" => name_statuses(:legitimate).id,
              "name_rank_id" => name_ranks(:species).id,
              "name_type_id" => name_types(:scientific).id,
              "parent_id" => @name.id,
              "parent_typeahead" => @name.full_name,
              "name_element" => "readercreated",
            },
          },
          headers: { "Accept" => "application/javascript" },
          xhr: true
      end
    end
    assert_response :forbidden
  end
end
