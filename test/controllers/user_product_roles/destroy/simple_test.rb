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
class UserProductRoleDestroySimpleTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:user_one)
    @user_product_role = user_product_roles(:user_one_foa_draft_profile_editor)
  end

  test "destroy user product role simple" do
    assert_difference("User::ProductRole.count", -1) do
      sign_in_as_fake_user(
        username: @admin.user_name,
        full_name: "#{@admin.given_name} #{@admin.family_name}",
        groups: [ "admin" ]
      ) do
        delete user_product_roles_delete_path(
          user_id: @user_product_role.user_id,
          product_role_id: @user_product_role.product_role_id
        ),
          as: :turbo_stream
      end
      assert_response :success
    end
  end
end
