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

# A name must not be newly linked to a soft deleted name through parent_id,
# second_parent_id, duplicate_of_id or family_id. Existing links are left alone.
class NameValidationsSoftDeletedLinksTest < ActiveSupport::TestCase
  setup do
    @name = names(:hybrid_formula)
    @soft_deleted = names(:has_no_instances)
    @soft_deleted.update_column(:deleted_at, Time.current)
  end

  { parent_id: "parent name",
    second_parent_id: "second parent name",
    duplicate_of_id: "name it duplicates",
    family_id: "family name" }.each do |foreign_key, label|
    test "rejects a soft deleted #{label}" do
      @name.public_send("#{foreign_key}=", @soft_deleted.id)
      @name.valid?
      assert_includes @name.errors[:base],
                      "The #{label} has been soft deleted and cannot be used"
    end
  end

  test "keeps a parent link made before the parent was soft deleted" do
    @name.parent.update_column(:deleted_at, Time.current)
    @name.reload.verbatim_rank = "xx"
    @name.valid?
    assert_not(@name.errors[:base].any? { |e| e.include?("soft deleted") },
               @name.errors.full_messages.join("; "))
  end
end
