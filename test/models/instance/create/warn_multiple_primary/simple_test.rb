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
class InstCreateWarnMultiplePrimarySimpleTest < ActiveSupport::TestCase
  test "instance warning for multiple primary instance" do
    name = names(:to_have_double_primary)
    assert name.instances.size == 1, "Should have 1 instance"
    assert name.instances.first.instance_type.primary?, "Should be primary"
    i2 = name.instances.new
    i2.instance_type = instance_types(:nom_nov)
    i2.reference = references(:simple)
    i2.created_by = "test"
    i2.updated_by = "test"
    assert_raises(
      ActiveRecord::RecordInvalid,
      "Second primary instance should be rejected",
    ) do
      i2.save!
    end
    name_after = Name.find(name.id)
    assert name_after.instances.size == 1,
      "Should still be only 1 primary instance"
  end
end
