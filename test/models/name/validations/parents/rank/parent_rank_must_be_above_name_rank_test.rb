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
class ParentRankMustBeAboveNameRank < ActiveSupport::TestCase
  test "scientific name with parent of lower rank is invalid" do
    name = names(:scientific_name)
    assert name.valid?, "Scientific name should start out valid."
    name.name_rank = name_ranks(:genus)
    name.parent.name_rank = name_ranks(:species)
    assert_not name.valid?,
               "Parent name rank should not be lower than name's rank."
  end

  test "scientific name with parent of same rank is invalid" do
    name = names(:scientific_name)
    assert name.valid?, "Scientific name should start out valid."
    name.name_rank = name_ranks(:species)
    name.parent.name_rank = name_ranks(:species)
    assert_not name.valid?,
               "Parent name rank should not be the same as name's rank."
  end
end
