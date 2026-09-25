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

# Single Name model test.
class NameCannotBeItsOwnSecondParentTest < ActiveSupport::TestCase
  test "name with itself as second parent is invalid" do
    name = names(:hybrid_formula)
    assert name.valid?,
      "Name should be valid. Errs: #{name.errors.full_messages.join("; ")}"
    name.second_parent_id = name.id
    assert_not name.valid?,
      "Name should not be valid when it is its own second parent."
    assert_equal "Second parent cannot be the same record",
      name.errors.full_messages.join("; ")
  end
end
