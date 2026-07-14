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
#
# Editing a scientific name "as" a phrase name offers only the [n/a] status,
# so the status select must default to it. The name's stored status
# (legitimate) is not among a phrase name's options, so without a default the
# select renders blank.
class ConvertScientificToPhraseNameTest < ActionController::TestCase
  tests NamesController
  setup do
    @name = names(:a_species)
    @request.headers["Accept"] = "application/javascript"
  end

  def get_edit_as(new_category)
    get(:edit_as_category,
        params: { id: @name.id,
                  tab: "edit_name",
                  new_category: new_category },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: ["edit"] })
  end

  test "the name under test is a scientific name with a legitimate status" do
    assert_equal "scientific", @name.name_category.name
    assert_equal "legitimate", @name.name_status.name
  end

  test "editing a scientific name as a phrase name renders the edit tab" do
    get_edit_as(NameCategory::PHRASE_NAME)
    assert_response :success, "Cannot edit a scientific name as a phrase name"
    assert_select "select#name_name_status_id", true,
                  "Should show the name status select."
  end

  test "editing a scientific name as a phrase name offers only the [n/a] status" do
    get_edit_as(NameCategory::PHRASE_NAME)
    assert_select "select#name_name_status_id" do
      assert_select "option[value=?]", name_statuses(:na).id.to_s,
                    { count: 1 },
                    "Should offer the [n/a] status."
      assert_select "option[value=?]", name_statuses(:legitimate).id.to_s,
                    { count: 0 },
                    "Should not offer a scientific-only status."
    end
  end

  test "editing a scientific name as a phrase name defaults the status to [n/a]" do
    get_edit_as(NameCategory::PHRASE_NAME)
    assert_select "select#name_name_status_id" do
      assert_select "option[selected][value=?]", name_statuses(:na).id.to_s,
                    { count: 1 },
                    "Status should default to [n/a] for a phrase name."
    end
  end

  test "editing a scientific name as a scientific name keeps its own status" do
    get_edit_as(NameCategory::SCIENTIFIC_CATEGORY)
    assert_response :success
    assert_select "select#name_name_status_id" do
      assert_select "option[selected][value=?]",
                    name_statuses(:legitimate).id.to_s,
                    { count: 1 },
                    "Status should stay on the name's own status."
    end
  end
end
