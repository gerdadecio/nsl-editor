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
class InstanceNoteKeyAPCOptionsTest < ActiveSupport::TestCase
  test "instance note key apc options" do
    assert_equal 2,
                 InstanceNoteKey.apc_options.size,
                 "Expected 2 APC options"
    assert_match instance_note_keys(:apc_comment).name,
                 InstanceNoteKey.apc_options.first.first,
                 "First APC option should be 'APC Comment'"
    assert_match instance_note_keys(:apc_dist).name,
                 InstanceNoteKey.apc_options.last.first,
                 "Last APC option should be 'APC Dist.'"
  end
end
