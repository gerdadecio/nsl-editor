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

# Name type is scientific test.
class NoOthersAreScientificTest < ActiveSupport::TestCase
  # Instead of confirming all the non-scientific name types,
  # test for the scientific ones and
  # also test for a limited number of scientific name types.
  test "no others are scientific name types" do
    assert_equal 10,
                 NameType.where(scientific: true).size,
                 'Expecting exactly 10 "scientific" name types'
  end
end
