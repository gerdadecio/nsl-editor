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

# Single name controller test.
#
# app/views/names/details/_meta.html.erb (rendered by the name details tab) renders
# AuditHelper#updated_by_api_and_when, which adds a "Bulk changed" audit
# line when @name.api_at is set.
class NameShowEditorDetailsTabShowsBulkChangedWhenApiAtPresentTest < ActionController::TestCase
  tests NamesController
  setup do
    @name = names(:a_species)
    @api_at = 2.days.ago
  end

  test "shows a Bulk changed line with api_name and api_at" do
    @name.update_columns(api_name: "sample-api-user", api_at: @api_at)
    show_details_tab
    assert_match(/Bulk changed/, response.body)
    assert_match(/2 days&nbsp;ago/, response.body)
    expected = "by sample-api-user #{I18n.l(@name.reload.api_at, format: :default)}"
    assert_match(/#{Regexp.escape(expected)}/, response.body)
  end

  test "shows unknown in the Bulk changed line when api_name is blank" do
    @name.update_columns(api_name: nil, api_at: @api_at)
    show_details_tab
    expected = "by unknown #{I18n.l(@name.reload.api_at, format: :default)}"
    assert_match(/#{Regexp.escape(expected)}/, response.body)
  end

  test "renders the Bulk changed markup rather than escaping it" do
    @name.update_columns(api_name: "sample-api-user", api_at: @api_at)
    show_details_tab
    assert_no_match(/&lt;br&gt;Bulk changed/, response.body)
    assert_no_match(/&lt;span class=/, response.body)
  end

  test "escapes html in api_name" do
    @name.update_columns(api_name: "<b>bad</b>", api_at: @api_at)
    show_details_tab
    assert_match(/by &lt;b&gt;bad&lt;\\?\/b&gt;/, response.body)
  end

  private

  def show_details_tab
    @request.headers["Accept"] = "application/javascript"
    get(:show,
        params: { id: @name.id, tab: "tab_details" },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: ["edit"] })
    assert_response :success
  end
end
