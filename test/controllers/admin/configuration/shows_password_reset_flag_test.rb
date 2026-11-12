# frozen_string_literal: true

#   Copyright 2026 Australian National Botanic Gardens
#   This file is part of the NSL Editor.
#   Licensed under the Apache License, Version 2.0
require "test_helper"

# NSL-6047: the password_reset_enabled feature flag is on the Admin Config page.
class AdminConfigurationShowsPasswordResetFlagTest < ActionDispatch::IntegrationTest
  test "admin configuration page lists password_reset_enabled" do
    sign_in_as_fake_user(username: "fred", full_name: "Fred Jones", groups: [ "admin" ]) do
      get admin_path, xhr: true
    end

    assert_response :success
    assert_match(/password_reset_enabled/, response.body)
    assert_match(/password_reset_group.*unknown-group \(not set, so nobody can reset passwords\)/m, response.body)
  end
end
