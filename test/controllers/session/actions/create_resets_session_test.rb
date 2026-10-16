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

# Successful sign-in starts a new session (no session fixation) but keeps the deep link.
class SessionsCreateResetsSessionTest < ActionDispatch::IntegrationTest
  def with_ldap_sign_in(valid: true, &block)
    SignIn.stub_any_instance(:save, valid) do
      SignIn.stub_any_instance(:groups, [ "login", "edit" ]) do
        SignIn.stub_any_instance(:user_full_name, "Fred Jones") do
          SignIn.stub_any_instance(:user_cn, "fred") do
            SignIn.stub_any_instance(:generic_active_directory_user, false, &block)
          end
        end
      end
    end
  end

  def sign_in_params
    { sign_in: { username: "Fred", password: "secret" } }
  end

  test "sign in issues a new session id and keeps the deep link" do
    get search_path(query_target: "name", query_string: "acacia")
    assert_redirected_to start_sign_in_url
    deep_link = session[:url_after_sign_in]
    assert_match(/acacia/, deep_link)
    assert deep_link.start_with?("/search"), "Deep link should be a path, not a full URL: #{deep_link}"
    session_id_before_sign_in = session.id.to_s

    with_ldap_sign_in { post sign_in_path, params: sign_in_params }

    assert_redirected_to deep_link
    assert_not_equal session_id_before_sign_in, session.id.to_s, "Sign-in should start a new session"
    assert_equal "fred", session[:username]
    assert session[:url_after_sign_in].blank?, "Deep link should be used up after the redirect"
  end

  test "failed sign in keeps the deep link for the next attempt" do
    get search_path(query_target: "name", query_string: "acacia")
    deep_link = session[:url_after_sign_in]

    with_ldap_sign_in(valid: false) { post sign_in_path, params: sign_in_params }
    assert_response :unprocessable_content
    assert_equal deep_link, session[:url_after_sign_in]

    with_ldap_sign_in { post sign_in_path, params: sign_in_params }
    assert_redirected_to deep_link
  end

  test "only a local path is followed as a deep link" do
    controller = SessionsController.new
    assert controller.send(:local_path?, "/search?query_string=acacia")
    assert_not controller.send(:local_path?, "https://evil.example.com/search")
    assert_not controller.send(:local_path?, "//evil.example.com/search")
    assert_not controller.send(:local_path?, "/\\evil.example.com/search")
    assert_not controller.send(:local_path?, "")
    assert_not controller.send(:local_path?, nil)
  end

  test "sign in without a deep link goes to root" do
    with_ldap_sign_in { post sign_in_path, params: sign_in_params }

    assert_redirected_to root_path
    assert_equal "fred", session[:username]
  end
end
