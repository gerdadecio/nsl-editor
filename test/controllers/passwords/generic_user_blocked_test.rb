# frozen_string_literal: true

#   Copyright 2015 Australian National Botanic Gardens
#   This file is part of the NSL Editor.
#   Licensed under the Apache License, Version 2.0
require "test_helper"

# Generic Active Directory users can't change their password, whichever
# step of the flow they reach.
class PasswordsGenericUserBlockedTest < ActionDispatch::IntegrationTest
  GENERIC = { generic_active_directory_user: true }.freeze

  test "generic user going straight to the form gets the error page" do
    sign_in_as_fake_user(extra_session: GENERIC) do
      get show_password_form_path
    end
    assert_response :success
    assert_template :edit_error
    assert_select "input[name='password[new_password]']", count: 0
  end

  test "generic user opening change password gets the error page" do
    sign_in_as_fake_user(extra_session: GENERIC) do
      get edit_password_path
    end
    assert_template :edit_error
  end

  test "generic user posting a new password gets the error page" do
    Password.stub_any_instance(:save!, -> { flunk("save! should not be called") }) do
      sign_in_as_fake_user(extra_session: GENERIC) do
        post update_password_path, params: { password: { current_password: "a", new_password: "b", new_password_confirmation: "b" } }
      end
    end
    assert_template :edit_error
  end

  test "other users still see the form" do
    sign_in_as_fake_user do
      get show_password_form_path
    end
    assert_response :success
    assert_template :show_password_form
    assert_select "input[name='password[new_password]']"
  end
end
