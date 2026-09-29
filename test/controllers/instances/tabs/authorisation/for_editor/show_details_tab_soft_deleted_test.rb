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

# Single instance controller test.
#
# app/views/instances/tabs/_tab_show_1.html.erb renders
# AuditHelper#soft_deleted_by_whom_and_when, which adds a "Record soft deleted"
# audit line when soft delete is enabled and @instance.deleted_at is set.
class InstanceShowEditorDetailsTabSoftDeletedTest < ActionController::TestCase
  tests InstancesController
  setup do
    @instance = instances(:triodia_in_brassard)
    @deleted_at = 3.days.ago
    @original_soft_delete_enabled = Rails.configuration.try(:soft_delete_enabled)
    Rails.configuration.soft_delete_enabled = true
  end

  teardown do
    Rails.configuration.soft_delete_enabled = @original_soft_delete_enabled
  end

  test "shows a Record soft deleted line with who and when" do
    @instance.update_columns(deleted_at: @deleted_at, updated_by: "sample-deleter")
    show_details_tab
    assert_match(/Record soft deleted/, response.body)
    assert_match(/3 days&nbsp;ago/, response.body)
    expected = "by sample-deleter #{I18n.l(@instance.reload.deleted_at, format: :default)}"
    assert_match(/#{Regexp.escape(expected)}/, response.body)
  end

  test "renders the Record soft deleted markup rather than escaping it" do
    @instance.update_columns(deleted_at: @deleted_at, updated_by: "sample-deleter")
    show_details_tab
    assert_no_match(/&lt;br&gt;Record soft deleted/, response.body)
  end

  test "hides the Record soft deleted line when deleted_at is nil" do
    @instance.update_columns(deleted_at: nil)
    show_details_tab
    assert_no_match(/Record soft deleted/, response.body)
  end

  test "hides the Record soft deleted line when soft delete is disabled" do
    Rails.configuration.soft_delete_enabled = false
    @instance.update_columns(deleted_at: @deleted_at, updated_by: "sample-deleter")
    show_details_tab
    assert_no_match(/Record soft deleted/, response.body)
  end

  private

  def show_details_tab
    @request.headers["Accept"] = "application/javascript"
    get(:show,
        params: { id: @instance.id, tab: "tab_show_1" },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: ["edit"] })
    assert_response :success
  end
end
