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

# Reference DOI uniqueness validation tests.
class RefDoiUniquenessTest < ActiveSupport::TestCase
  test "doi must be unique" do
    ref_with_doi = references(:stanley_and_ross_1986_flora_of_se_qld)
    duplicate = references(:simple)
    duplicate.doi = ref_with_doi.doi
    assert_not duplicate.valid?, "Should be invalid when doi duplicates another record"
    assert duplicate.errors[:doi].any?, "Should have a doi error"
  end

  test "nil doi is allowed even when other records have nil doi" do
    ref = references(:simple)
    assert_nil ref.doi
    assert ref.valid?, "Should be valid with nil doi"
  end
end
