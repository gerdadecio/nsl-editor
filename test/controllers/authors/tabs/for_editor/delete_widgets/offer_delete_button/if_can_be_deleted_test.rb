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

# Single controller test.
class AuthorEditorOfferDeleteButtonIfCanBeDelTest < ActionController::TestCase
  tests AuthorsController

  test "should show editor author delete button if can be deleted" do
    author = authors(:has_no_dependents)
    @request.headers["Accept"] = "application/javascript"
    assert author.can_be_deleted?,
           "Must be able to delete this author for the test to be valid"
    get(:show,
        params: { id: author.id, tab: "tab_edit" },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: ["edit"] })
    assert_select "li.active a#author-edit-tab",
                  "Edit",
                  "Should show 'Edit' tab."
    assert_select "a#author-delete-link", true
  end
end
