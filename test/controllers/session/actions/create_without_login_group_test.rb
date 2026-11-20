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

# A correct password for an account without the login group must fail exactly
# like a wrong password, so sign-in can't be used to check passwords for AD
# accounts (NSL-6059).
class SessionsCreateWithoutLoginGroupTest < ActionDispatch::IntegrationTest
  # Stubs Ldap#save rather than SignIn#save, so SignIn's own validation runs
  # and adds its message.
  def with_ldap_sign_in(valid:, groups:, &block)
    Ldap.stub_any_instance(:save, valid) do
      SignIn.stub_any_instance(:groups, groups, &block)
    end
  end

  def sign_in_params
    { sign_in: { username: "Fred", password: "secret" } }
  end

  test "a wrong password shows credentials not verified" do
    with_ldap_sign_in(valid: false, groups: []) { post sign_in_path, params: sign_in_params }

    assert_response :unprocessable_content
    assert_select "#error_explanation li", "Credentials not verified."
  end

  test "a correct password without the login group shows the same message as a wrong password" do
    with_ldap_sign_in(valid: true, groups: [ "edit" ]) { post sign_in_path, params: sign_in_params }

    assert_response :unprocessable_content
    assert_select "#error_explanation li", "Credentials not verified."
    assert_no_match(/authori[sz]ed/i, response.body)
    assert_nil session[:username]
  end

  test "a correct password without the login group keeps the session like a wrong password does" do
    get search_path(query_target: "name", query_string: "acacia")
    deep_link = session[:url_after_sign_in]
    session_id = session.id.to_s

    with_ldap_sign_in(valid: true, groups: [ "edit" ]) { post sign_in_path, params: sign_in_params }

    assert_response :unprocessable_content
    assert_equal session_id, session.id.to_s, "A refused sign-in should not start a new session"
    assert_equal deep_link, session[:url_after_sign_in]
  end
end
