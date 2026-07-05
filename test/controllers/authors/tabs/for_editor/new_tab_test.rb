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
class AuthorEditorNewTest < ActionController::TestCase
  tests AuthorsController
  setup do
    @author = Author.new
  end

  test "author should get new author tab" do
    skip
    # 2015-08-31 15:07:00.840 [hmm] Security warning:
    #      an embedded <script> tag on another site
    #      requested protected JavaScript. If you know what you're doing,
    #      go ahead and disable forgery
    #      protection on this action to permit cross-origin
    #      JavaScript embedding. (pid:78529)
    @request.headers["Accept"] = "application/javascript"
    get(:new,
        params: { random_id: "12345" },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: ["edit"] })
    # puts response.body
    # assert_select "li.active a#author-edit-tab",
    #               "Edit",
    #               "Should show 'Edit' tab."
    assert_select "form", true
    assert_select "input#author_name", true
    assert_select "input#author_abbrev", true
    assert_select "input#author_full_name", true
    assert_select "textarea#author_notes", true
    # assert_select 'input#author_duplicate_of_id', true
  end
end
