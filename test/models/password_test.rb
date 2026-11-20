# frozen_string_literal: true

#   Copyright 2026 Australian National Botanic Gardens
#   This file is part of the NSL Editor.
#   Licensed under the Apache License, Version 2.0

require "test_helper"
require "minitest/mock"

# NSL-6058: the password is only changed once AD has accepted the current
# password. An LDAP error during that check must stop the change.
class PasswordTest < ActiveSupport::TestCase
  def password
    Password.new(
      username: "fred",
      current_password: "Old-password1",
      new_password: "New-password1",
      new_password_confirmation: "New-password1",
    )
  end

  # Runs save! with Ldap#verify_current_password and #connection_failed?
  # stubbed, and records whether change_password was reached.
  def save_with(verified:, connection_failed: false)
    changed = false
    pw = password
    Ldap.stub_any_instance(:verify_current_password, verified) do
      Ldap.stub_any_instance(:connection_failed?, connection_failed) do
        Ldap.stub_any_instance(:change_password, ->(*) { changed = true }) do
          [ pw.save!, pw, changed ]
        end
      end
    end
  end

  test "the password is changed when the current password is verified" do
    saved, pw, changed = save_with(verified: true)

    assert saved, pw.error
    assert changed
  end

  test "a wrong current password stops the change" do
    saved, pw, changed = save_with(verified: false)

    assert_not saved
    assert_not changed
    assert_equal "current password is wrong", pw.error
  end

  test "an LDAP error checking the current password stops the change" do
    saved, pw, changed = save_with(verified: false, connection_failed: true)

    assert_not saved
    assert_not changed
    assert_match(/could not check your current password/i, pw.error)
  end
end
