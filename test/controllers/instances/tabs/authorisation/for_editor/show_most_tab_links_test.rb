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
class InstanceForEditorShowMostTabsTest < ActionController::TestCase
  tests InstancesController
  setup do
    @instance = instances(:britten_created_angophora_costata)
    @request.headers["Accept"] = "application/javascript"
  end

  test "should show all tab links if editor requests details tab" do
    get(:show,
        params: { id: @instance.id,
                  tab: "tab_show_1",
                  "row-type" => "instance_as_part_of_concept_record" },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: ["edit"] })
    asserts
  end

  def asserts
    asserts1
    asserts2
    asserts3
    asserts4
  end

  def asserts1
    assert_response :success
    assert_select "li.active a#instance-show-tab",
                  /Details/,
                  "Does not show 'Details' tab link."
    assert_select "a#instance-edit-tab",
                  /Edit/,
                  "Does not show 'Edit' tab link."
    assert_select "a#instance-edit-notes-tab",
                  /Notes/,
                  "Does not show 'Notes' tab link."
  end

  def asserts2
    assert_select "a#instance-cite-this-instance-tab",
                  /Syn/,
                  "Does not show 'Syn' tab link."
    assert_select "a#unpublished-citation-tab",
                  /Unpub/,
                  "Does not show 'Unpub' tab link."
    assert_select "a#instance-apc-placement-tab",
                  false,
                  "Should not show 'APC' tab link."
  end

  def asserts3
    assert_select "a#instance-comments-tab",
                  /Adnot/,
                  "Does not show 'Adnot' tab link."
    assert_select "a#instance-copy-to-new-reference-tab",
                  /Copy/,
                  "Should show 'Copy' tab link."
  end

  def asserts4
    assert_select "a#instance-profile-v2-tab",
                  false
                  "Should not show 'FOA Profile' tab link"
  end
end
