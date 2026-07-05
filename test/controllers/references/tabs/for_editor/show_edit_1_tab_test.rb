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
class ReferenceEditorShowEdit1TabTest < ActionController::TestCase
  tests ReferencesController
  setup do
    @reference = references(:a_book)
  end

  test "should show editor reference edit 1 tab" do
    @request.headers["Accept"] = "application/javascript"
    get(:show,
        params: { id: @reference.id, tab: "tab_edit_1" },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: ["edit"] })
    assert_select "li.active a#reference-edit-1-tab",
                  /Edit\./,
                  "Should show 'Edit 1' tab."
    assert_select "form", true
    assert_select "select#reference_ref_type_id", true
    assert_select "input#reference-parent-typeahead", true
    assert_select "input#reference_title", true
    assert_select "input#reference_published", true
    assert_select "input#reference-author-typeahead", true
    assert_select "select#reference_ref_author_role_id", true
    assert_select "input#reference_edition", true
    assert_select "input#reference_volume", true
    assert_select "input#reference_pages", true
    assert_select "input#reference_day", true
    assert_select "select#reference_month", true
    assert_select "input#reference_year", true
    assert_select "input#reference_publication_date", true
    assert_select "textarea#reference_notes", true
  end
end
