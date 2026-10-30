# frozen_string_literal: true

#   Copyright 2015 Australian National Botanic Gardens
#   This file is part of the NSL Editor.
#   Licensed under the Apache License, Version 2.0
#
require "test_helper"

# The New User form explains that it does not set up sign-in to the Editor.
class UserNewExplanationTest < ActionDispatch::IntegrationTest
  test "new user form explains that adding a user does not let them log in" do
    sign_in_as_fake_user(groups: [ "admin" ]) do
      get new_user_with_random_id_path(random_id: 123),
        params: { format: "js", tabIndex: 40 },
        xhr: true
    end
    assert_response :success
    assert_select "#new-user-form-explanation", /does not let them log in to the Editor/
    assert_select "#new-user-form-explanation", /ActiveDirectory/
    assert_select "#new-user-form-explanation", /before they log in for the first time/
  end
end
