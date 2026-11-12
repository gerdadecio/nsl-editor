# frozen_string_literal: true

#   Copyright 2026 Australian National Botanic Gardens
#   This file is part of the NSL Editor.
#   Licensed under the Apache License, Version 2.0
require "test_helper"
require "minitest/mock"
require_relative "../../../support/fake_password_reset_directory"

# NSL-6047: the Password tab on a user record is for password administrators,
# and only when password reset is turned on.
class UsersTabsPasswordTabTest < ActionDispatch::IntegrationTest
  setup do
    @original_enabled = Rails.configuration.try(:password_reset_enabled)
    @original_group = Rails.configuration.try(:password_reset_group)
    Rails.configuration.password_reset_enabled = true
    Rails.configuration.password_reset_group = "password-admin"
    @user = users(:user_one)
    @directory = FakePasswordResetDirectory.new
  end

  teardown do
    Rails.configuration.password_reset_enabled = @original_enabled
    Rails.configuration.password_reset_group = @original_group
  end

  def show_tab(tab, groups, username: "anna")
    Ldap::PasswordResetDirectory.stub(:new, @directory) do
      sign_in_as_fake_user(username: username, full_name: "Anna Admin", groups: groups) do
        get user_show_path, params: { id: @user.id, tab: tab }, headers: { "Accept" => "application/javascript" }
      end
    end
  end

  def show_password_tab(**options)
    show_tab("tab_password", [ "login", "password-admin" ], **options)
    assert_response :success
  end

  def assert_no_form_and_message(text)
    assert_select "form#password-reset-form", count: 0
    assert_select "p#password-reset-check-message.error-container", text: /#{Regexp.escape(text)}/
  end

  test "a password administrator sees the Password tab and its form" do
    show_tab("tab_password", [ "login", "password-admin" ])
    assert_response :success
    assert_select "a#user-password-tab"
    assert_select "form#password-reset-form input[type=password][name='password_reset[admin_password]']"
    assert_select "input#password-reset-submit[data-disable-with]"
    assert_includes response.body, "Check who's asking"
    assert_includes response.body, "Only NSL accounts can be reset here"
    assert_select "label[for=password_reset_admin_password] span.red", text: "*"
    assert_select "#password-reset-error-message-container.error-container"
    assert_select "#password-reset-check-message", count: 0
    assert_select "#password-reset-locked-message", count: 0
  end

  test "an account that isn't an NSL account gets a message instead of the form" do
    @user = users(:user_two)
    show_password_tab
    assert_no_form_and_message("utwo isn't an NSL account in Active Directory")
  end

  test "a disabled account gets a message instead of the form" do
    @directory = FakePasswordResetDirectory.new(target_disabled: true)
    show_password_tab
    assert_no_form_and_message("is disabled in Active Directory")
  end

  test "a password administrator's account gets a message instead of the form" do
    @directory.protected = true
    show_password_tab
    assert_no_form_and_message("is a password administrator")
  end

  test "your own account gets a message instead of the form" do
    show_password_tab(username: "uone")
    assert_no_form_and_message("Use Change Password")
  end

  test "a locked-out account shows the form, saying it will be unlocked" do
    @directory = FakePasswordResetDirectory.new(target_locked: true)
    show_password_tab
    assert_select "form#password-reset-form"
    assert_select "#password-reset-locked-message", text: /locked out/
  end

  test "if AD can't be reached the form still shows, with a note" do
    @directory.fail_search = true
    show_password_tab
    assert_select "form#password-reset-form"
    assert_select "p#password-reset-check-message", text: /couldn't be reached/
  end

  test "no AD lookup for someone who can't reset passwords" do
    @directory.fail_search = true
    show_tab("tab_password", [ "login", "admin" ])
    assert_response :success
    assert_select "#password-reset-check-message", count: 0
  end

  test "a password administrator can see the Details tab but not Edit or Roles" do
    show_tab("tab_details", [ "login", "password-admin" ])
    assert_response :success
    assert_select "a#user-password-tab"
    assert_select "a#user-edit-tab", count: 0
    assert_select "a#user-roles-tab", count: 0
  end

  test "a password administrator can't open the Edit tab" do
    show_tab("tab_edit", [ "login", "password-admin" ])
    assert_response :forbidden
  end

  test "an admin who isn't in password-admin has no Password tab or form" do
    show_tab("tab_password", [ "login", "admin" ])
    assert_response :success
    assert_select "a#user-password-tab", count: 0
    assert_select "form#password-reset-form", count: 0
  end

  test "with no group configured, password-admin gives no access" do
    Rails.configuration.password_reset_group = nil
    show_tab("tab_password", [ "login", "password-admin" ])
    assert_response :forbidden
  end

  test "no Password tab when the feature is off" do
    Rails.configuration.password_reset_enabled = nil
    show_tab("tab_password", [ "login", "password-admin" ])
    assert_response :forbidden
  end
end
