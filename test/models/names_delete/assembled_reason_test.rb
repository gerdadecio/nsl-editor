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

# NamesDelete#assembled_reason joins reason and extra_info together and is
# what actually gets sent (URL-encoded) to the external delete service via
# Name::AsServices#delete_with_reason. It must never exceed 254 characters,
# regardless of how the two pieces combine - the UI's own maxlength on
# extra_info (199) is only a soft guard, this is the hard one.
class NamesDeleteAssembledReasonTest < ActiveSupport::TestCase
  LONGEST_PRESET_REASON = "Name is an autonym that has not yet been established"

  def name_id
    names(:scientific_name).id
  end

  test "assembled reason is just the reason when extra_info is blank" do
    names_delete = NamesDelete.new(name_id: name_id,
                                    reason: "Name does not exist",
                                    extra_info: "")
    assert_equal "Name does not exist", names_delete.assembled_reason
  end

  test "assembled reason joins reason and extra_info with a semicolon" do
    names_delete = NamesDelete.new(name_id: name_id,
                                    reason: "Other",
                                    extra_info: "Duplicate of another name")
    assert_equal "Other; Duplicate of another name",
                 names_delete.assembled_reason
  end

  test "assembled reason is untouched at exactly 254 characters" do
    reason = "Other"
    extra_info = "X" * (254 - "#{reason}; ".length)
    names_delete = NamesDelete.new(name_id: name_id,
                                    reason: reason,
                                    extra_info: extra_info)
    result = names_delete.assembled_reason
    assert_equal 254, result.length
    assert_not result.end_with?("..."),
               "Should not be truncated at exactly 254 characters"
    assert_equal "#{reason}; #{extra_info}", result
  end

  test "assembled reason is truncated to 254 characters when over the limit" do
    reason = "Other"
    extra_info = "X" * 300
    names_delete = NamesDelete.new(name_id: name_id,
                                    reason: reason,
                                    extra_info: extra_info)
    result = names_delete.assembled_reason
    assert_equal 254, result.length
    assert result.end_with?("..."), "Should be truncated with an ellipsis"
    assert result.start_with?("#{reason}; "),
           "Truncation should preserve the reason at the start"
  end

  test "assembled reason stays within 254 chars even with the longest " \
       "preset reason and a full-length extra_info" do
    extra_info = "X" * 200
    names_delete = NamesDelete.new(name_id: name_id,
                                    reason: LONGEST_PRESET_REASON,
                                    extra_info: extra_info)
    result = names_delete.assembled_reason
    assert result.length <= 254,
           "Combined reason + extra_info must never exceed 254 characters, " \
           "was #{result.length}"
  end
end
