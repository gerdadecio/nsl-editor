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
require "minitest/mock"

# Sign-in attempts are rate limited per client IP, per username and overall
# (NSL-6052).
#
# The test environment uses :null_store, which never counts, so these tests
# stub the store's increment to stand in for the attempt counts. Each limit
# has its own key ("rate-limit:sessions:<name>:<by>"), so the stub returns a
# count per limit name, and records the keys it was asked about.
#
# The stub goes on the controller's store instance, not on NullStore with
# stub_any_instance: NullStore prepends LocalCache, so stub_any_instance thinks
# NullStore doesn't own increment and removes NullStore#increment when it
# restores. Every later sign-in then raises NotImplementedError from
# Store#increment.
class SessionsCreateRateLimitTest < ActionDispatch::IntegrationTest
  # Limits not given a count report one attempt.
  def with_attempt_counts(ip: 1, username: 1, global: 1, &block)
    counts = { "ip" => ip, "username" => username, "global" => global }
    @rate_limit_keys = []
    increment = lambda do |key, *_args, **_options|
      @rate_limit_keys << key
      counts.fetch(key.split(":")[2])
    end
    SessionsController.cache_store.stub(:increment, increment, &block)
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

  test "the tenth attempt from one IP is still allowed" do
    with_attempt_counts(ip: 10) do
      with_ldap_sign_in { post sign_in_path, params: sign_in_params }
    end

    assert_redirected_to root_path
    assert_equal "fred", session[:username]
  end

  test "the eleventh attempt from one IP is refused without asking LDAP" do
    # SignIn#save is not stubbed: if create ran, it would try LDAP, fail, and
    # redirect to retry_start_sign_in instead of rendering the 429.
    with_attempt_counts(ip: 11) do
      post sign_in_path, params: sign_in_params
    end

    assert_response :too_many_requests
    assert_select "#error_explanation", /Too many sign-in attempts/
    assert session[:username].blank?, "A refused attempt should not sign in"
  end

  test "the sign-in page itself is not rate limited" do
    with_attempt_counts(ip: 11, username: 6, global: 101) do
      get start_sign_in_path
    end

    assert_response :success
  end

  test "the fifth attempt for one username is still allowed" do
    with_attempt_counts(username: 5) do
      with_ldap_sign_in { post sign_in_path, params: sign_in_params }
    end

    assert_redirected_to root_path
    assert_equal "fred", session[:username]
  end

  test "the sixth attempt for one username is refused without asking LDAP" do
    with_attempt_counts(username: 6) do
      post sign_in_path, params: sign_in_params
    end

    assert_response :too_many_requests
    assert_select "#error_explanation", /Too many sign-in attempts/
    assert session[:username].blank?, "A refused attempt should not sign in"
  end

  test "usernames are counted case- and whitespace-insensitively" do
    with_attempt_counts do
      [ "Fred", " fred ", "FRED" ].each do |username|
        with_ldap_sign_in { post sign_in_path, params: { sign_in: { username: username, password: "secret" } } }
      end
    end

    username_keys = @rate_limit_keys.grep(/:username:/).uniq
    assert_equal [ "rate-limit:sessions:username:fred" ], username_keys
  end

  test "the hundredth sign-in attempt overall is still allowed" do
    with_attempt_counts(global: 100) do
      with_ldap_sign_in { post sign_in_path, params: sign_in_params }
    end

    assert_redirected_to root_path
  end

  test "the hundred-and-first sign-in attempt overall is refused without asking LDAP" do
    with_attempt_counts(global: 101) do
      post sign_in_path, params: sign_in_params
    end

    assert_response :too_many_requests
    assert_select "#error_explanation", /Too many sign-in attempts/
    assert session[:username].blank?, "A refused attempt should not sign in"
  end

  test "malformed sign-in params don't break the username limit" do
    with_attempt_counts do
      post sign_in_path, params: { sign_in: "not a hash" }
    end

    assert_redirected_to retry_start_sign_in_path
    assert_includes @rate_limit_keys, "rate-limit:sessions:username:"
  end
end
