# frozen_string_literal: true

#   Copyright 2026 Australian National Botanic Gardens
#   This file is part of the NSL Editor.
#   Licensed under the Apache License, Version 2.0
require "test_helper"
require "minitest/mock"
require_relative "../../../support/fake_password_reset_directory"

# NSL-6047: POST from the Password tab on a user record.
class UserPasswordResetsCreateTest < ActionDispatch::IntegrationTest
  setup do
    @original_enabled = Rails.configuration.try(:password_reset_enabled)
    @original_group = Rails.configuration.try(:password_reset_group)
    Rails.configuration.password_reset_enabled = true
    Rails.configuration.password_reset_group = "password-admin"
    @directory = FakePasswordResetDirectory.new
    @user = users(:user_one)
  end

  teardown do
    Rails.configuration.password_reset_enabled = @original_enabled
    Rails.configuration.password_reset_group = @original_group
  end

  def post_reset(groups: [ "login", "password-admin" ], admin_password: "right-password", extra_session: {})
    Ldap::PasswordResetDirectory.stub(:new, @directory) do
      sign_in_as_fake_user(username: "anna", full_name: "Anna Admin", groups: groups, extra_session: extra_session) do
        post user_password_reset_path(@user),
          params: { password_reset: { admin_password: admin_password } },
          xhr: true,
          headers: { "Accept" => "text/javascript" }
      end
    end
  end

  test "a password administrator gets the temporary password in the response" do
    post_reset
    assert_response :success
    password = @directory.resets.first.last
    assert_includes response.body, password
    assert_includes response.body, "has been reset"
  end

  test "an administrator signed in with a generic AD account can reset too" do
    post_reset(extra_session: { generic_active_directory_user: true })
    assert_response :success
    assert_equal 1, @directory.resets.size
  end

  test "the response is never cached, and the password isn't kept" do
    post_reset
    password = @directory.resets.first.last
    assert_equal "no-store", response.headers["Cache-Control"]
    assert flash.empty?
    assert_no_match(/#{password}/, session.to_hash.to_s)
  end

  test "a refusal shows the reason and resets nothing" do
    post_reset(admin_password: "wrong")
    assert_response :unprocessable_content
    assert_includes response.body, "Your password was not accepted."
    assert_empty @directory.resets
  end

  test "an admin who isn't in password-admin is refused" do
    post_reset(groups: [ "login", "admin" ])
    assert_response :forbidden
    assert_empty @directory.resets
  end

  test "refused when the feature is off" do
    Rails.configuration.password_reset_enabled = nil
    post_reset
    assert_response :forbidden
    assert_empty @directory.resets
  end

  test "the administrator's password is filtered from the log" do
    filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
    filtered = filter.filter("password_reset" => { "admin_password" => "right-password" })
    assert_no_match(/right-password/, filtered.to_s)
  end

  test "too many attempts are stopped before AD is asked" do
    User::PasswordResetsController.cache_store.stub(:increment, 6) do
      post_reset
    end
    assert_response :too_many_requests
    assert_includes response.body, "Too many password reset attempts"
    assert_empty @directory.resets
  end
end
