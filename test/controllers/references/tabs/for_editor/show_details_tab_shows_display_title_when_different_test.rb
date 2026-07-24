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
# app/views/references/tabs/_tab_show_1.html.erb adds a "Display Title"
# detail_line when @reference.title != @reference.display_title.
# references(:simple) has title "  Simple  " and display_title
# "Display Title", so the two clearly differ.
class ReferenceShowEditorDetailsTabShowsDisplayTitleWhenDifferentTest < ActionController::TestCase
  tests ReferencesController
  setup do
    @reference = references(:simple)
  end

  test "shows a Display Title line when title and display_title differ" do
    @request.headers["Accept"] = "application/javascript"
    get(:show,
        params: { id: @reference.id, tab: "tab_show_1" },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: ["edit"] })
    assert_response :success
    assert_match(/Display Title/, response.body)
    assert_match(/#{Regexp.escape(@reference.display_title)}/, response.body)
  end
end
