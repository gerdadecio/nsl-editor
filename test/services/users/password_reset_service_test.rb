# frozen_string_literal: true

#   Copyright 2026 Australian National Botanic Gardens
#   This file is part of the NSL Editor.
#   Licensed under the Apache License, Version 2.0
require "test_helper"
require "minitest/mock"
require_relative "../../support/fake_password_reset_directory"

# NSL-6047: a password administrator resets another NSL user's AD password.
class UsersPasswordResetServiceTest < ActiveSupport::TestCase
  setup do
    @original_enabled = Rails.configuration.try(:password_reset_enabled)
    Rails.configuration.password_reset_enabled = true
    @directory = FakePasswordResetDirectory.new
    @user = users(:user_one)
  end

  teardown do
    Rails.configuration.password_reset_enabled = @original_enabled
  end

  def reset(admin_username: "anna", admin_password: "right-password")
    Users::PasswordResetService.call(
      user: @user,
      admin_username: admin_username,
      admin_password: admin_password,
      ip: "10.1.2.3",
      directory: @directory,
    )
  end

  def assert_refused(service, reason)
    assert_not service.success?
    assert_equal reason, service.reason
    assert_nil service.temporary_password
    assert_empty @directory.resets, "expected no password to be reset"
  end

  test "resets the password to a temporary one" do
    service = reset
    assert service.success?
    assert_match(/\A[A-Z][a-z]+[A-Z][a-z]+\d\d\z/, service.temporary_password)
    assert_equal [ [ @directory.target.dn, service.temporary_password ] ], @directory.resets
  end

  test "the temporary password avoids the user's names" do
    service = reset
    assert_not_includes service.temporary_password.downcase, "uone"
  end

  test "unlocks a locked-out account" do
    @directory = FakePasswordResetDirectory.new(target_locked: true)
    service = reset
    assert service.success?
    assert service.unlocked
    assert_equal [ @directory.target.dn ], @directory.unlocks
  end

  test "leaves an account that isn't locked alone" do
    service = reset
    assert_not service.unlocked
    assert_empty @directory.unlocks
  end

  test "a failed unlock still reports the reset, with a warning" do
    @directory = FakePasswordResetDirectory.new(target_locked: true)
    @directory.fail_unlock = true
    service = reset
    assert service.success?
    assert service.unlock_failed
  end

  test "refused when the feature is off" do
    Rails.configuration.password_reset_enabled = nil
    assert_refused(reset, "feature-off")
  end


  test "refused for the administrator's own account" do
    @user = users(:user_one)
    @user.update_columns(user_name: "anna")
    assert_refused(reset, "self")
  end

  test "refused when the administrator's password is blank" do
    assert_refused(reset(admin_password: ""), "no-admin-password")
  end

  test "refused when the administrator's password is wrong" do
    assert_refused(reset(admin_password: "wrong"), "bad-admin-password")
  end

  test "refused when the administrator is no longer in password-admin in AD" do
    @directory = FakePasswordResetDirectory.new(admin_groups: [ "login", "admin" ])
    assert_refused(reset, "not-password-admin")
  end

  test "refused when the user isn't in the NSL users OU" do
    @user = users(:user_two)
    assert_refused(reset, "not-found")
  end

  test "refused for a disabled account" do
    @directory = FakePasswordResetDirectory.new(target_disabled: true)
    assert_refused(reset, "disabled")
  end

  test "refused for another password administrator" do
    @directory.protected = true
    assert_refused(reset, "protected-group")
  end

  test "admins are not protected" do
    assert_equal [ "password-admin" ], Users::PasswordResetService::PROTECTED_GROUPS
  end

  test "tries a new password when AD's policy refuses one" do
    @directory.policy_failures = 2
    service = reset
    assert service.success?
    assert_equal 1, @directory.resets.size
  end

  test "gives up with a clear message if AD's policy keeps refusing" do
    @directory.policy_failures = Users::PasswordResetService::POLICY_ATTEMPTS
    service = reset
    assert_refused(service, "policy")
    assert_match(/password policy/, service.errors.full_messages.first)
  end

  test "an AD error refuses the reset without showing the raw error" do
    @directory.fail_search = true
    service = reset
    assert_refused(service, "error")
    assert_no_match(/search failed/, service.errors.full_messages.first)
  end

  test "logs one PASSWORD_RESET line for a success, without the password" do
    lines = capture_log { @service = reset }
    assert_equal 1, lines.grep(/PASSWORD_RESET/).size
    line = lines.grep(/PASSWORD_RESET/).first
    assert_match(/admin=anna target=uone result=success reason=- unlocked=no ip=10\.1\.2\.3/, line)
    assert_no_match(/#{@service.temporary_password}/, lines.join)
    assert_no_match(/right-password/, lines.join)
  end

  test "logs refused attempts with the reason" do
    lines = capture_log { reset(admin_password: "wrong") }
    assert_match(/PASSWORD_RESET admin=anna target=uone result=refused reason=bad-admin-password/, lines.grep(/PASSWORD_RESET/).first)
    assert_no_match(/wrong/, lines.join)
  end

  test "check_target is fine for an ordinary account" do
    check = Users::PasswordResetService.check_target(@user, admin_username: "anna", directory: @directory)
    assert check.resettable?
    assert_nil check.reason
    assert_not check.locked
  end

  test "check_target gives the same reasons as the reset" do
    @directory.protected = true
    check = Users::PasswordResetService.check_target(@user, admin_username: "anna", directory: @directory)
    assert_not check.resettable?
    assert_equal "protected-group", check.reason
    assert_equal reset.errors.full_messages.first, check.message
  end

  test "check_target spots the administrator's own account" do
    check = Users::PasswordResetService.check_target(@user, admin_username: "UONE", directory: @directory)
    assert_equal "self", check.reason
  end

  test "check_target reports a locked-out account" do
    @directory = FakePasswordResetDirectory.new(target_locked: true)
    assert Users::PasswordResetService.check_target(@user, admin_username: "anna", directory: @directory).locked
  end

  test "check_target still allows a try when AD can't be reached" do
    @directory.fail_search = true
    check = Users::PasswordResetService.check_target(@user, admin_username: "anna", directory: @directory)
    assert_equal "unavailable", check.reason
    assert check.resettable?
  end

  private

  def capture_log
    output = StringIO.new
    logger = ActiveSupport::Logger.new(output)
    Rails.stub(:logger, logger) { yield }
    output.string.lines
  end
end
