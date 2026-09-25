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

def test_reference_text_field_change_is_detected(field_name)
  reference = Reference::AsEdited.find(references(:for_change_detection).id)
  new_column_value = "changed"
  user_name = "a user"
  assert(
    reference
        .update_if_changed({ field_name => new_column_value },
          {},
          user_name),
    "Reference should have been changed.",
  )
  assert_changed(field_name, reference, new_column_value, user_name)
end

def assert_changed(field_name, reference, new_column_value, user_name)
  changed_reference = Reference.find_by(id: reference.id)
  assert_match(
    new_column_value,
    changed_reference.send(field_name),
    "#{field_name} should have changed to the new value",
  )
  assert_match(
    user_name,
    changed_reference.updated_by,
    "Reference.updated_by should have changed to the updating user",
  )
  assert(
    reference.created_at < changed_reference.updated_at,
    "Reference updated at should have changed.",
  )
end

def test_reference_text_field_lack_of_change_is_detected(field_name)
  reference = Reference::AsEdited.find(references(:for_change_detection).id)
  unchanged_field_value = reference.send(field_name)
  assert(reference.update_if_changed(
    { field_name => unchanged_field_value },
    {},
    "a user",
  ))
  assert_unchanged(field_name, reference)
end

def assert_unchanged(field_name, reference)
  changed_reference = Reference.find_by(id: reference.id)
  assert_match(
    reference.send(field_name) || "isnil",
    changed_reference.send(field_name) || "isnil",
    "#{field_name} should not have changed",
  )
  assert_equal(
    reference.updated_at,
    changed_reference.updated_at,
    "Reference should not have been updated.",
  )
end
