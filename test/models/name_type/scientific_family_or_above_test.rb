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

# NameType.scientific_family_or_above is used to populate the Type dropdown
# when adding a new scientific name at family rank or above. It should
# behave like NameType.scientific_1_parent_options, except that 'autonym'
# is never offered - autonyms can only exist at infrageneric or
# infraspecific ranks (see NameRank#compatible_with_autonym?), never at
# family or above.
class ScientificFamilyOrAboveTest < ActiveSupport::TestCase
  test "scientific family or above name type options" do
    part1
    part2
    part3
  end

  def part1
    assert_equal 3,
                 NameType.scientific_family_or_above.size,
                 "Should be 3 scientific-family-or-above name types."
  end

  def part2
    names = NameType.scientific_family_or_above.collect(&:first)
    assert names.include?("scientific"),
           "'scientific' should be a scientific-family-or-above name type."
    assert names.include?("sanctioned"),
           "'sanctioned' should be a scientific-family-or-above name type."
    assert names.include?("named hybrid autonym"),
           "'named hybrid autonym' should be a scientific-family-or-above " \
           "name type."
  end

  def part3
    names = NameType.scientific_family_or_above.collect(&:first)
    assert_not names.include?("autonym"),
               "'autonym' should NOT be a scientific-family-or-above " \
               "name type - it's invalid at family rank and above."
    assert_not names.include?("phrase name"),
               "'phrase name' should NOT be a scientific-family-or-above " \
               "name type."
    assert_not names.include?("named hybrid"),
               "'named hybrid' should NOT be a scientific-family-or-above " \
               "name type (it's a hybrid, not the named-hybrid-autonym " \
               "exception)."
    assert_not names.include?("hybrid formula parents known"),
               "'hybrid formula parents known' should NOT be a " \
               "scientific-family-or-above name type."
  end
end
