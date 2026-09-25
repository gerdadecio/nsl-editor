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
class InstanceAsCopierCopyStandaloneWithNewNameIdTest < ActiveSupport::TestCase
  test "copy one standalone instance with a new name id" do
    before = Instance.count
    master_instance = Instance::AsCopier.find(
      instances(:triodia_in_brassard).id,
    )
    target_name = names(:no_instances)
    before_for_name = target_name.instances.count
    dummy_username = "fred"
    copied_instance = master_instance.copy_with_new_name_id(
      target_name.id,
      dummy_username,
    )
    after = Instance.count
    after_for_name = target_name.instances.count
    assert_equal before + 1, after, "There should be one extra instance."
    assert_equal before_for_name + 1,
      after_for_name,
      "There should be 1 extra instance attached to the target name."
    assert_equal copied_instance.name_id, target_name.id
    assert_equal copied_instance.reference_id, master_instance.reference_id
    assert_equal dummy_username, copied_instance.created_by
    assert_equal dummy_username, copied_instance.updated_by
  end
end
