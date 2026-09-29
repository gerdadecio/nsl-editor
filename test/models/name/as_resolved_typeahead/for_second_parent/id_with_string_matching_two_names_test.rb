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
class NameARTA4Parent2IdWithStringMatching2Names < ActiveSupport::TestCase
  test "id with string matching 2 names" do
    name_2 = names(:name_matches_another_2)
    result = Name::AsResolvedTypeahead::ForParent.new(
      name_2.id.to_s,
      name_2.full_name,
      "second_parent"
    )
    assert_equal name_2.id,
                 result.value,
                 "Should get a match for the correct id"
  end
end
