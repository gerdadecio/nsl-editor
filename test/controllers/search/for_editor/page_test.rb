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
class SearchControllerForEditorPageTest < ActionDispatch::IntegrationTest

  test "editor should get search with correct elements" do
    sign_in_as_fake_user(
      username: "fred",
      full_name: "Fred Jones",
      groups: ["edit"]
    ) do
      get search_path, params: {}
    end
    assert_response :success
    assert_select "a#new-dropdown-menu-link.dropdown-toggle",
                  /New/,
                  "Should show New menu link."
    assert_select "a#help-dropdown-menu-link.dropdown-toggle",
                  /Help/,
                  "Should show Help menu link."
    assert_select "a#user-dropdown-menu-link.dropdown-toggle",
                  true,
                  "Should show User menu link."
    assert_select "a#admin-dropdown-menu-link.dropdown-toggle",
                  true,
                  "Should show Admin menu link."
  end
end
