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
class ReferenceUnauthenticatedShowNoTabLinkTest < ActionController::TestCase
  tests ReferencesController
  setup do
    @reference = references(:a_book)
  end

  test "should show no tab links if unauthenticated requests details tab" do
    @request.headers["Accept"] = "application/javascript"
    get(:show,
        params: { id: @reference.id, tab: "tab_edit" },
        session: {})
    # assert_response :redirect, 'Should be redirected.'
    assert_select "a#reference-show-tab", false, "Should not show 'Detail' tab."
    assert_select "a#reference-edit-tab", false, "Should not show 'Edit' tab."
    assert_select "a#reference-comments-tab",
                  false,
                  "Should not show 'Comments' tab."
    assert_select "a#tab-heading",
                  false,
                  "Should not have tab heading showing a_book."
  end
end
