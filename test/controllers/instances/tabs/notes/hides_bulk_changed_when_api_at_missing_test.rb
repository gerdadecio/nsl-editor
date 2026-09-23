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
# app/views/instance_notes/_form.html.erb is rendered for each existing
# note on the instance notes tab. It renders
# AuditHelper#updated_by_api_and_when, which adds nothing when
# instance_note.api_at is blank - even if api_name is set.
class InstanceTabsNotesHidesBulkChangedWhenApiAtMissingTest < ActionController::TestCase
  tests InstancesController
  setup do
    @instance = instances(:triodia_in_brassard)
    @instance_note = instance_notes(:one)
  end

  test "hides the Bulk changed line when api_name and api_at are blank" do
    @instance_note.update_columns(api_name: nil, api_at: nil)
    show_notes_tab
    assert_no_match(/Bulk changed/, response.body)
  end

  test "hides the Bulk changed line when only api_name is set" do
    @instance_note.update_columns(api_name: "sample-api-user", api_at: nil)
    show_notes_tab
    assert_no_match(/Bulk changed/, response.body)
  end

  private

  def show_notes_tab
    @request.headers["Accept"] = "application/javascript"
    get(:show,
        params: { id: @instance.id, tab: "tab_edit_notes" },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: ["edit"] })
    assert_response :success
    assert_select "form#edit_instance_note_#{@instance_note.id}", 1,
                  "Needs the edit form for the existing note."
  end
end
