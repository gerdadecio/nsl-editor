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
require "test_helper"

# Single user controller test.
#
# app/views/users/tabs/_tab_details.html.erb renders
# AuditHelper#updated_by_api_and_when, which adds nothing when
# @user.api_at is blank - even if api_name is set.
class UsersTabsForAdminDetailsTabHidesBulkChangedWhenApiAtMissingTest < ActionController::TestCase
  tests UsersController
  setup do
    @user = users(:user_one)
  end

  test "hides the Bulk changed line when api_name and api_at are blank" do
    @user.update_columns(api_name: nil, api_at: nil)
    show_details_tab
    assert_no_match(/Bulk changed/, response.body)
  end

  test "hides the Bulk changed line when only api_name is set" do
    @user.update_columns(api_name: "sample-api-user", api_at: nil)
    show_details_tab
    assert_no_match(/Bulk changed/, response.body)
  end

  private

  def show_details_tab
    @request.headers["Accept"] = "application/javascript"
    get(
      :show,
      params: { id: @user.id, tab: "tab_details" },
      session: {
        username: "fred",
        user_full_name: "Fred Jones",
        groups: ["admin"],
      },
    )
    assert_response(:success)
    assert_match(/User ##{@user.id}/, response.body)
  end
end
