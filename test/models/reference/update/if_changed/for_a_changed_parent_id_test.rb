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
require "models/reference/update/if_changed/test_helper"
require "models/reference/update/if_changed/stub_helper"

# Single Reference model test.
class ForAChangedParentIdTest < ActiveSupport::TestCase
  setup do
    stub_it
  end

  test "changed parent id" do
    reference = Reference::AsEdited
      .find(references(:for_resolving_typeaheads).id)
    new_parent = references(:for_change_detection)
    assert_not_equal new_parent.id,
      reference.parent_id,
      "Test setup broken if new parent same as the old parent."
    new_column_value = new_parent.id
    assert reference
      .update_if_changed({},
        {
          "parent_typeahead" => new_parent.citation,
          "parent_id" => new_column_value,
        },
        "a user"),
      "Reference should have been changed."
    changed_reference = Reference.find_by(id: reference.id)
    assert_equal new_column_value,
      changed_reference.parent_id,
      "The parent_id col value should have changed to the new value"
    assert_match "a user",
      changed_reference.updated_by,
      "Reference.updated_by should have changed to the updating user"
    assert reference.created_at < changed_reference.updated_at,
      "Reference updated at should have changed."
  end
end
