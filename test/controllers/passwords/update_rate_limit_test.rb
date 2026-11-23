# frozen_string_literal: true

#   Copyright 2015 Australian National Botanic Gardens
#   This file is part of the NSL Editor.
#   Licensed under the Apache License, Version 2.0
require "test_helper"
require "minitest/mock"

# Password changes are rate limited per signed-in user, so a session can't be
# used to guess the current password without limit (NSL-6060).
#
# The test environment uses :null_store, which never counts, so these tests
# stub increment on the controller's store instance (see
# SessionsCreateRateLimitTest for why not stub_any_instance on NullStore).
class PasswordsUpdateRateLimitTest < ActionDispatch::IntegrationTest
  def with_attempt_count(count, &block)
    @rate_limit_keys = []
    increment = lambda do |key, *_args, **_options|
      @rate_limit_keys << key
      count
    end
    PasswordsController.cache_store.stub(:increment, increment, &block)
  end

  # Counts for real, in one MemoryStore.
  def with_real_counts(&block)
    store = ActiveSupport::Cache::MemoryStore.new
    increment = lambda do |key, amount = 1, **options|
      store.increment(key, amount, **options)
    end
    PasswordsController.cache_store.stub(:increment, increment, &block)
  end

  def password_params
    { password: { current_password: "wrong", new_password: "NewPass1!", new_password_confirmation: "NewPass1!" } }
  end

  def failed_change_as(username)
    Password.stub_any_instance(:save!, false) do
      sign_in_as_fake_user(username: username) do
        post update_password_path, params: password_params
      end
    end
  end

  test "the fifth attempt is still allowed" do
    with_attempt_count(5) do
      Password.stub_any_instance(:save!, true) do
        sign_in_as_fake_user { post update_password_path, params: password_params }
      end
    end

    assert_redirected_to password_changed_path
  end

  test "the sixth attempt is refused without asking AD" do
    with_attempt_count(6) do
      Password.stub_any_instance(:save!, -> { flunk("save! should not be called") }) do
        sign_in_as_fake_user { post update_password_path, params: password_params }
      end
    end

    assert_response :too_many_requests
    assert_template :show_password_form
    assert_select "#error-explanation", /Too many password change attempts/
  end

  test "attempts are counted against the signed-in user" do
    with_attempt_count(1) do
      failed_change_as("fred")
    end

    assert_equal [ "rate-limit:passwords:password-username:fred" ], @rate_limit_keys
  end

  test "the password form itself is not rate limited" do
    with_attempt_count(6) do
      sign_in_as_fake_user { get show_password_form_path }
    end

    assert_response :success
  end

  test "repeated failed attempts are counted up to the limit" do
    with_real_counts do
      PasswordsController::PER_USER_LIMIT.times do
        failed_change_as("fred")
        assert_response :unprocessable_content
      end

      failed_change_as("fred")
      assert_response :too_many_requests
    end
  end

  test "a refused user doesn't block other users" do
    with_real_counts do
      (PasswordsController::PER_USER_LIMIT + 1).times { failed_change_as("fred") }
      assert_response :too_many_requests

      failed_change_as("mary")
      assert_response :unprocessable_content
    end
  end
end
