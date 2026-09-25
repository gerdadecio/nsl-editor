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
class FromHybridFormulaUnk2ndParentToHybridFormulaTest < ActiveSupport::TestCase
  test "convert name from hyb form unkn 2nd par - to - hybrid formula test" do
    skip
  end

  def skipped
    name = names(:hybrid_name_with_unknown_2nd_parent)
    assert_equal(
      name.raw_category,
      Name::SCIENTIFIC_HYBRID_FORMULA_UNKNOWN_2ND_PARENT_CATEGORY,
    )
    assert(name.valid?, "hybrid name with unknown 2nd parent should be valid")

    name.change_category_to = Name::SCIENTIFIC_HYBRID_FORMULA_CATEGORY
    assert_equal(name.category, Name::SCIENTIFIC_HYBRID_FORMULA_CATEGORY)

    assert_not(
      name.valid?,
      "hybrid name with unknown 2nd parent should not be valid
               now as a hybrid with two parents",
    )
    assert(name.errors.size == 2, "There should be two errors.")
    assert(
      name.errors.collect { |k, _v| k.to_s }.include?("name_type_id"),
      "There should be an error for name_type_id.",
    )
    assert(
      name.errors.collect { |k, _v| k.to_s }.include?("second_parent_id"),
      "There should be an error for second_parent_id.",
    )

    name.name_type_id =
      NameType.find_by(name: "hybrid formula parents known").id
    name.second_parent_id = names(:another_species).id

    assert(
      name.valid?,
      "hybrid w/ unk 2nd par should be valid now as hybrid with 2 parents",
    )
    name.save!
    assert(
      name.raw_category == Name::SCIENTIFIC_HYBRID_FORMULA_CATEGORY,
      "name should now be a scientific hybrid with two parents",
    )
  end
end
