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

# An instance must not be newly linked to a soft deleted instance through
# cites_id, cited_by_id or parent_id. Existing links are left alone.
class InstanceValidationsSoftDeletedLinksTest < ActiveSupport::TestCase
  setup do
    @instance = instances(:xyz_costata_is_synonym_of_angophora_costata)
    @soft_deleted = instances(:rusty_gum_is_a_common_name_of_angophora_costata)
    @soft_deleted.update_column(:deleted_at, Time.current)
  end

  { cites_id: "cited instance",
    cited_by_id: "citing instance",
    parent_id: "parent instance" }.each do |foreign_key, label|
    test "rejects a soft deleted #{label}" do
      @instance.public_send("#{foreign_key}=", @soft_deleted.id)
      @instance.valid?
      assert_includes @instance.errors[:base],
                      "The #{label} has been soft deleted and cannot be used"
    end
  end

  test "keeps a citation made before the cited instance was soft deleted" do
    @instance.this_cites.update_column(:deleted_at, Time.current)
    @instance.reload.page = "xx,21"
    @instance.valid?
    assert_not(@instance.errors[:base].any? { |e| e.include?("soft deleted") },
               @instance.errors.full_messages.join("; "))
  end
end
