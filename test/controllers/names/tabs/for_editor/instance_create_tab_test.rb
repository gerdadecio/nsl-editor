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
class InstanceCreateTabTest < ActionController::TestCase
  tests NamesController
  setup do
    @name = names(:a_species)
  end

  test "instance create for name" do
    @request.headers["Accept"] = "application/javascript"
    get(:show,
        params: { id: @name.id, tab: "tab_instances" },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: ["edit"] })
    assert_response :success
    assert_template "names/tabs/_tab"
    assert_template "names/tabs/_tab_instances"
    assert_select ".focus-details" do
      assert_select "span.message", count: 0
      assert_select "form"
      assert_select "input#instance-reference-typeahead"
      assert_select "select#instance_instance_type_id"
      assert_select "input#instance_page"
      assert_select "input#instance_verbatim_name_string"
      assert_select "input#instance_bhl_url"
    end
    assert_template partial: "instances/_form_create_from_name"
  end
end
