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
class NameShowInstanceTabForEditorTest < ActionController::TestCase
  tests NamesController
  setup do
    @name = names(:a_species)
  end

  test "should show new instance tab" do
    @request.headers["Accept"] = "application/javascript"
    get(:show,
        params: { id: @name.id, tab: "tab_instances" },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: ["edit"] },
        xhr: true)
    assert_response :success
    assert_select "li.active a#name-instances-tab",
                  "New instance",
                  "Should show 'New instance' tab."
  end
end
