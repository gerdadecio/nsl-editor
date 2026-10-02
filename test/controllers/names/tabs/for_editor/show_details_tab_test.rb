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
class NameShowDetailsTabForEditor < ActionDispatch::IntegrationTest
  setup do
    @name = names(:a_species)
  end

  test "should show name to editor" do
    # NOTE: pre-existing anomaly, preserved as-is: groups: [:edit] uses a
    # symbol, but SessionUser#edit? checks groups.include?("edit") (a
    # string), so this never actually granted edit permission. Doesn't
    # change this test's outcome since the default tab doesn't require
    # edit access.
    sign_in_as_fake_user(
      username: "fred",
      full_name: "Fred Jones",
      groups: [ :edit ]
    ) do
      get name_tab_path(id: @name, tab: "tab_details"),
        headers: { "Accept" => "application/javascript" }
    end
    assert_response :success
  end
end
