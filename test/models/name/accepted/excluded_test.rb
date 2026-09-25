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

# Single name model test.
class NameAPCExcludedTest < ActiveSupport::TestCase
  test "name apc excluded" do
    skip "need to convert this away from services using tree data"
    name = Name.new
    expected_instance_id = 44
    name.stubs(:get_apc_json).returns(
      "inAPC" => true,
      "excluded" => true,
      "taxonId" => expected_instance_id.to_s,
      "type" => "ApcExcluded",
    )
    assert_equal true, name.accepted_concept?, "Name should be in APC"
    assert_equal expected_instance_id,
      name.accepted_instance_id,
      "APC instance id should be set"
    assert_equal false, name.apc_declared_bt, "Name should not be a declared BT"
    assert_equal true,
      name.apc_instance_is_an_excluded_name,
      "Should be an excluded name"
  end
end
