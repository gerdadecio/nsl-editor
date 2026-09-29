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

# Single instance note key model test.
class InstNoteKeyAPCOptionsForInstanceWithAPCDistTest < ActiveSupport::TestCase
  test "instance note key apc options for instance with apc dist" do
    instance = instances(:has_apc_dist_note)
    options = InstanceNoteKey.apc_options_for_instance(instance)
    assert_equal 1,
                 options.size,
                 "Expected 1 APC option"
    assert_match instance_note_keys(:apc_comment).name,
                 options.first.first,
                 "First APC option should be 'APC Comment'"
  end
end
