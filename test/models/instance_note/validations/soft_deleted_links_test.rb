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

# An instance note must not be pointed at a soft deleted instance.
class InstanceNoteSoftDeletedLinksTest < ActiveSupport::TestCase
  MESSAGE = "The instance has been soft deleted and cannot be used"

  setup do
    @note = instance_notes(:one)
    @soft_deleted = instances(:a_soft_deleted_instance)
  end

  test "rejects moving a note to a soft deleted instance" do
    @note.instance_id = @soft_deleted.id
    assert_not @note.valid?
    assert_includes @note.errors[:base], MESSAGE
  end

  test "rejects a new note on a soft deleted instance" do
    note = InstanceNote.new(instance: @soft_deleted,
                            instance_note_key: instance_note_keys(:neotype),
                            value: "a note")
    assert_not note.valid?
    assert_includes note.errors[:base], MESSAGE
  end

  test "keeps an existing note on an instance soft deleted later" do
    @note.instance.update_column(:deleted_at, Time.current)
    @note.reload
    @note.value = "#{@note.value}x"
    assert(@note.valid?, @note.errors.full_messages.join("; "))
  end
end
