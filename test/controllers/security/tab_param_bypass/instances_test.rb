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
# can("instances", "tab_show_1"); InstancesController#destroy then only
# checks :modify, which every user has.
class TabParamBypassInstancesTest < ActionDispatch::IntegrationTest
  setup do
    @instance = instances(:triodia_in_brassard)
    stub_request(:any, /localhost:9090/).to_return(status: 200, body: "{}")
  end

  test "reader cannot delete an instance by adding a permitted tab param" do
    sign_in_as_fake_user(username: "fred", full_name: "Fred Jones", groups: []) do
      delete instance_path(id: @instance.id, tab: "tab_show_1"),
        headers: { "Accept" => "application/javascript" }
    end
    assert_response :forbidden
    # The delete itself happens in the services app; make sure we never asked.
    assert_not_requested :delete, /localhost:9090/
  end

  test "reader cannot update an instance by adding a permitted tab param" do
    sign_in_as_fake_user(username: "fred", full_name: "Fred Jones", groups: []) do
      patch instance_path(id: @instance.id, tab: "tab_show_1"),
        params: { instance: { page: "reader was here" } },
        headers: { "Accept" => "application/javascript" }
    end
    assert_response :forbidden
    assert_not_equal "reader was here", @instance.reload.page
  end
end
