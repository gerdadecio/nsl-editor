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

# Single instance model test.
# No message was getting to the users - this was failing without enough fuss.
class InstCreateSaveWithUsernameThrowsExc4Duplicate < ActiveSupport::TestCase
  test "instance create save with username throws exception 4 dupe" do
    existing = instances(:metrosideros_costata_is_basionym_of_angophora_costata)
    dup = Instance.new(
      name_id: existing.name_id,
      reference_id: existing.reference_id,
      instance_type_id: existing.instance_type_id,
      cited_by_id: existing.cited_by_id,
      cites_id: existing.cites_id,
      page: existing.page,
    )
    assert_raises(
      ActiveRecord::RecordInvalid,
      "Instance save_with_username should throw exception 4 dup",
    ) do
      dup.save_with_username("fred")
    end
  end
end
