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

# A user with only the login group must not reach the Resource tab.
class NameForbidResourceTabForReaderTest < ActionDispatch::IntegrationTest
  setup do
    @name = names(:a_species)
  end

  test "login-only user requests forbidden resource tab" do
    sign_in_as_fake_user(
      username: "fred",
      full_name: "Fred Jones",
      groups: [ "login" ]
    ) do
      get name_tab_path(id: @name.id, tab: "tab_resource"),
        headers: { "Accept" => "application/javascript" }
    end
    assert_response :forbidden
  end

  test "login-only user cannot create a name resource" do
    sign_in_as_fake_user(
      username: "fred",
      full_name: "Fred Jones",
      groups: [ "login" ]
    ) do
      assert_no_difference("NameResource.count") do
        post name_name_resources_path(@name),
          params: { name_resource: { value: "x" } },
          headers: { "Accept" => "text/vnd.turbo-stream.html" }
      end
    end
    assert_response :forbidden
  end
end
