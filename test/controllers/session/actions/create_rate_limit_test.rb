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

# Sign-in attempts are rate limited per client IP.
#
# The test environment uses :null_store, which never counts, so these tests
# stub the store's increment to stand in for the attempt count.
class SessionsCreateRateLimitTest < ActionDispatch::IntegrationTest
  def with_attempt_count(count, &block)
    ActiveSupport::Cache::NullStore.stub_any_instance(:increment, count, &block)
  end

  def with_ldap_sign_in(&block)
    SignIn.stub_any_instance(:save, true) do
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

  test "the tenth attempt is still allowed" do
    with_attempt_count(10) do
      with_ldap_sign_in { post sign_in_path, params: sign_in_params }
    end

    assert_redirected_to root_path
    assert_equal "fred", session[:username]
  end

  test "the eleventh attempt is refused without asking LDAP" do
    # SignIn#save is not stubbed: if create ran, it would try LDAP, fail, and
    # redirect to retry_start_sign_in instead of rendering the 429.
    with_attempt_count(11) do
      post sign_in_path, params: sign_in_params
    end

    assert_response :too_many_requests
    assert_select "#error_explanation", /Too many sign-in attempts/
    assert session[:username].blank?, "A refused attempt should not sign in"
  end

  test "the sign-in page itself is not rate limited" do
    with_attempt_count(11) do
      get start_sign_in_path
    end

    assert_response :success
  end
end
