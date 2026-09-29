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

# Single author model test.
class AuthTypeOnNameDOTwoAuthorsSameNameWithRefCount < ActiveSupport::TestCase
  test "author typeahead on name dup of two authors same name" do
    result = Author::AsTypeahead.on_name_duplicate_of("masl", -1)
    assert_equal 2, result.size, "Expecting 2 records for 'masl'."
    values = result.collect { |author| author[:value] }
    assert values.include?("Maslin, B.R. | 1 ref"),
           "Expecting Maslin with 1 ref."
    assert values.include?("Maslin, B.R. | Maslin"),
           "Expecting Maslin with 0 refs mentioned."
  end
end
