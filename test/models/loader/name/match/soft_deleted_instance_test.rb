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

# A loader name match must not be pointed at a soft deleted instance.
class LoaderNameMatchSoftDeletedInstanceTest < ActiveSupport::TestCase
  setup do
    @match = loader_name_matches(:match_zzz_test_parent_with_match)
    @soft_deleted = instances(:xyz_costata_is_synonym_of_angophora_costata)
    @soft_deleted.update_column(:deleted_at, Time.current)
  end

  { instance_id: "instance",
    standalone_instance_id: "standalone instance",
    relationship_instance_id: "relationship instance",
    source_for_copy_instance_id: "source instance for copy" }.each do |foreign_key, label|
    test "rejects a soft deleted #{label}" do
      @match.public_send("#{foreign_key}=", @soft_deleted.id)
      @match.valid?
      assert_includes @match.errors[:base],
                      "The #{label} has been soft deleted and cannot be used"
    end
  end

  test "keeps an existing link to an instance soft deleted later" do
    match = loader_name_matches(:match_zzz_test_parent_using_existing)
    match.update_column(:standalone_instance_id, @soft_deleted.id)
    match.reload
    assert(match.valid?, match.errors.full_messages.join("; "))
  end
end
