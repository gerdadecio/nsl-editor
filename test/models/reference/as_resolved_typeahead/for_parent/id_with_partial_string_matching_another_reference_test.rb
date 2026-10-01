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

# Reference model parent from typeahead test.
class RefARTA4ParentIdWPartStrMatchingAnotherRefTest < ActiveSupport::TestCase
  test "parent id with partial string for another reference" do
    reference_1 = references(:journal_of_botany_british_and_foreign)
    reference_2 = references(:origin_of_species)
    result = Reference::AsResolvedTypeahead::ForParent.new(
      reference_1.id.to_s,
      reference_2.citation.chop
    )
    assert_equal reference_2.id,
                 result.value,
                 "Should get matching ID for citation string despite \
                 mismatched ID and partial string"
  end
end
