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
class UserCreateSimpleTest < ActionDispatch::IntegrationTest
  def setup
    @known_user = users(:user_one)
  end

  test "create user simple" do
    assert_difference("User.count") do
      sign_in_as_fake_user(
        username: @known_user.user_name,
        full_name: "#{@known_user.given_name} #{@known_user.family_name}",
        groups: [ "admin" ]
      ) do
        post users_path,
          params: {
            user: {
              "user_name" => "auser",
              "given_name" => "a",
              "family_name" => "user",
            },
          },
          headers: { "Accept" => "application/javascript" }
      end
    end
  end

  test "created user is stamped with the creating user's user name" do
    sign_in_as_fake_user(
      username: @known_user.user_name,
      full_name: "#{@known_user.given_name} #{@known_user.family_name}",
      groups: [ "admin" ]
    ) do
      post users_path,
        params: {
          user: {
            "user_name" => "buser",
            "given_name" => "b",
            "family_name" => "user",
          },
        },
        headers: { "Accept" => "application/javascript" }
    end
    created = User.find_by(user_name: "buser")
    assert created.present?, "New user record should have been created"
    assert_equal(
      @known_user.user_name,
      created.created_by,
      "created_by should be the creating user's user name"
    )
    assert_equal(
      @known_user.user_name,
      created.updated_by,
      "updated_by should be the creating user's user name"
    )
  end
end
