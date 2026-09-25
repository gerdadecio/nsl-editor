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
class InstanceValidationDuplicatesPreventTest < ActiveSupport::TestCase
  test "instance prevent duplicate" do
    instance = instances(:triodia_in_brassard)
    assert instance.valid?, "Starting instance must be valid for this test."
    dup = instance.dup
    assert_raises(
      ActiveRecord::RecordInvalid,
      "Duplicate instance shouldn't be saved",
    ) do
      dup.save!
    end
  end
end
