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
class ReferenceEditorShowAllTabsTest < ActionController::TestCase
  tests ReferencesController
  setup do
    @reference = references(:a_book)
    @request.headers["Accept"] = "application/javascript"
  end

  test "should show all tab links if editor requests details tab" do
    get(:show,
        params: { id: @reference.id, tab: "tab_show_1" },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: ["edit"] })
    asserts1
    asserts2
    asserts3
  end

  def asserts1
    assert_response :success
    assert_select "li.active a#reference-edit-show-1-tab",
                  /Details/,
                  "Does not show 'Details' tab link."
    assert_select "a#reference-edit-1-tab",
                  /Edit\./,
                  "Does not show 'Edit.' tab link."
    assert_select "a#reference-edit-2-tab",
                  /Edit\.\./,
                  "Does not show 'Edit..' tab link."
  end

  def asserts2
    assert_select "a#reference-edit-3-tab",
                  /Edit\.\.\./,
                  "Does not show 'Edit...' tab link."
    assert_select "a#reference-comments-tab",
                  "Comments",
                  "Should show 'Comments' tab link."
    assert_select "a#reference-new-instance-tab",
                  /New instance/,
                  "Should show 'New instance' tab link."
  end

  def asserts3
    assert_select "a#tab-heading",
                  /A Book/,
                  "Should have tab heading showing 'A Book'."
  end
end
