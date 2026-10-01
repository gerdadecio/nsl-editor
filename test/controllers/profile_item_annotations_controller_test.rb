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

class ProfileItemAnnotationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user_product_role = user_product_roles(:user_one_foa_draft_profile_editor)
  end

  test "should create a profile item annotation" do
    assert_difference("Profile::ProfileItemAnnotation.count", 1) do
      profile_item = profile_item(:notes_pi)
      sign_in_as_fake_user(
        username: "uone",
        full_name: "Fred Jones",
        groups: ["edit", "foa"]
      ) do
        post profile_item_annotations_path,
          params: {
            profile_item_annotation: {
              profile_item_id: profile_item.id,
              value: "New Annotation",
            },
          },
          xhr: true
      end
    end

    assert_equal assigns(:profile_item_annotation).value, "New Annotation"
    assert_response :success
    assert_template :create
  end

  test "should update profile item annotation" do
    profile_item = profile_item(:ecology_pi)
    profile_item_annotation = profile_item.profile_item_annotation
    sign_in_as_fake_user(
      username: "uone",
      full_name: "Fred Jones",
      groups: ["edit", "foa"]
    ) do
      put profile_item_annotation_path(profile_item_annotation),
        params: {
          profile_item_annotation: {
            value: "Updated Annotation",
          },
        },
        xhr: true
    end

    assert_response :success
    assert_equal profile_item_annotation.id, assigns(:profile_item_annotation).id
    assert_equal "Updated", assigns(:message)
    assert_equal "Updated Annotation", profile_item_annotation.reload.value
    assert_template :update
  end

  test "should not update if value has not changed" do
    profile_item = profile_item(:ecology_pi)
    profile_item_annotation = profile_item.profile_item_annotation
    sign_in_as_fake_user(
      username: "uone",
      full_name: "Fred Jones",
      groups: ["edit", "foa"]
    ) do
      put profile_item_annotation_path(profile_item_annotation),
        params: {
          profile_item_annotation: {
            value: profile_item_annotation.value,
          },
        },
        xhr: true
    end

    assert_response :success
    assert_equal profile_item_annotation.id, assigns(:profile_item_annotation).id
    assert_equal "No change", assigns(:message)
    assert_template :update
  end

  test "should handle error when update fails" do
    profile_item = profile_item(:ecology_pi)
    profile_item_annotation = profile_item.profile_item_annotation

    Profile::ProfileItemAnnotation.stub_any_instance(:update, false) do
      sign_in_as_fake_user(
        username: "uone",
        full_name: "Fred Jones",
        groups: ["edit", "foa"]
      ) do
        put profile_item_annotation_path(profile_item_annotation),
          params: {
            profile_item_annotation: {
              value: "New Value",
            },
          },
          xhr: true
      end

      assert_response :unprocessable_content
      assert_equal profile_item_annotation.id, assigns(:profile_item_annotation).id
      assert_template :update_failed
    end
  end

  test "should return validation error when update value is blank" do
    profile_item = profile_item(:ecology_pi)
    profile_item_annotation = profile_item.profile_item_annotation

    sign_in_as_fake_user(
      username: "uone",
      full_name: "Fred Jones",
      groups: ["edit", "foa"]
    ) do
      put profile_item_annotation_path(profile_item_annotation),
        params: {
          profile_item_annotation: {
            value: "",
          },
        },
        xhr: true
    end

    assert_response :unprocessable_content
    assert_match "can't be blank", assigns(:message)
    assert_template :update_failed
    assert profile_item_annotation.reload.value.present?
  end

  test "should destroy profile item annotation" do
    profile_item = profile_item(:ecology_pi)
    profile_item_annotation = profile_item.profile_item_annotation

    assert_difference("Profile::ProfileItemAnnotation.count", -1) do
      sign_in_as_fake_user(
        username: "uone",
        full_name: "Fred Jones",
        groups: ["edit", "foa"]
      ) do
        delete profile_item_annotation_path(profile_item_annotation), xhr: true
      end
    end

    assert_response :success
    assert_equal "Deleted", assigns(:message)
    assert_template :delete
  end
end
