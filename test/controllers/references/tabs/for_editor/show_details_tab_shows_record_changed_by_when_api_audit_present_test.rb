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

# Single reference controller test.
#
# app/views/references/tabs/_tab_show_1.html.erb adds a "Record changed by"
# audit line when @reference.api_name and @reference.api_at are both set.
class ReferenceShowEditorDetailsTabShowsRecordChangedByWhenApiAuditPresentTest < ActionController::TestCase
  tests ReferencesController
  setup do
    @reference = references(:simple)
    @api_at = Time.zone.local(2026, 9, 21, 14, 5)
    @reference.update_columns(api_name: "sample-api-user", api_at: @api_at)
  end

  test "shows a Record changed by line when api_name and api_at are set" do
    @request.headers["Accept"] = "application/javascript"
    get(:show,
        params: { id: @reference.id, tab: "tab_show_1" },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: ["edit"] })
    assert_response :success
    expected = "Record changed by: sample-api-user #{I18n.l(@api_at, format: :default)}"
    assert_match(/#{Regexp.escape(expected)}/, response.body)
  end
end
