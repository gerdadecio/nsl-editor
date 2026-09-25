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

def test_author_text_field_change_is_detected(field_name)
  author = Author::AsEdited.find(authors(:haeckel).id)
  new_column_value = "changed"
  assert(author.update_if_changed(
    { field_name => new_column_value },
    {},
    "a user",
  ))
  changed_author = Author.find_by(id: author.id)
  test_changed_value(author, changed_author, new_column_value, field_name)
end

def test_changed_value(author, changed_author, new_column_value, field_name)
  assert_match(
    new_column_value,
    changed_author.send(field_name),
    "#{field_name} should have changed to the new value",
  )
  assert_match(
    "a user",
    changed_author.updated_by,
    "Author.updated_by should have changed to the updating user",
  )
  assert(
    author.created_at < changed_author.updated_at,
    "Author updated at should have changed.",
  )
end

def test_author_text_field_lack_of_change_is_detected(field_name)
  author = Author::AsEdited.find(authors(:haeckel).id)
  unchanged_field_value = author.send(field_name)
  assert(author.update_if_changed(
    { field_name => unchanged_field_value },
    {},
    "a user",
  ))
  changed_author = Author.find_by(id: author.id)
  test_changed_author(author, changed_author, field_name)
end

def test_changed_author(author, changed_author, field_name)
  assert_match(
    author.send(field_name) || "isnil",
    changed_author.send(field_name) || "isnil",
    "#{field_name} should not have changed",
  )
  assert_equal(
    author.created_at,
    changed_author.updated_at,
    "Author should not have been updated.",
  )
end
