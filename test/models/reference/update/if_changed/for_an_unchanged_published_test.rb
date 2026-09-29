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

# Single Reference model test.
class ForAnUnchangedRefPublishedTest < ActiveSupport::TestCase
  test "unchanged published" do
    reference = Reference::AsEdited.find(
      references(:for_whole_record_change_detection).id
    )
    field_name = "published"
    unchanged_field_value = reference.send(field_name) ? 1 : 0
    assert reference.update_if_changed(
      { field_name => unchanged_field_value },
      {},
      "a user"
    )
    changed_reference = Reference.find_by(id: reference.id)
    assert_equal reference.send(field_name) || "isnil",
                 changed_reference.send(field_name) || "isnil",
                 "#{field_name} should not have changed"
    assert_equal reference.created_at,
                 changed_reference.updated_at,
                 "Reference should not have been updated."
  end
end
