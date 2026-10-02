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
class NameEditorShowAllTabsTest < ActionDispatch::IntegrationTest
  setup do
    @name = names(:a_species)
  end

  test "should show all tabs if editor requests details tab" do
    sign_in_as_fake_user(
      username: "fred",
      full_name: "Fred Jones",
      groups: [ "edit" ]
    ) do
      get name_tab_path(id: @name.id, tab: "tab_edit"),
        headers: { "Accept" => "application/javascript" }
    end
    assert_response :success
    assert_select "a#name-details-tab", true, "Should show 'Detail' tab."
    assert_select "a#name-edit-tab", true, "Should show 'Edit' tab."
    assert_select "a#name-instances-tab", true, "Should show 'New instance' tab."
    assert_select "a#name-copy-tab", true, "Should show 'Copy' tab."
    assert_select "a#name-delete-tab", true, "Should show 'Delete' tab."
    assert_select "a#name-more-tab", true, "Should show 'More' tab."
  end
end
