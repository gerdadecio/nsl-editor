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
#
# The suggestion list (Name::AsTypeahead.duplicate_suggestions) excludes
# records that are already themselves a duplicate via not_a_duplicate; this
# confirms the resolver applies the same exclusion when the user types an
# exact match for one of those records and saves without picking a
# suggestion, rather than silently resolving to it anyway.
class NameAsResolvedTANoDuplicateOfIdWithValidStringMatchingAnExistingDuplicate < ActiveSupport::TestCase
  test "no id with valid string matching an existing duplicate" do
    already_a_duplicate = names(:a_duplicate_species)
    other_name = names(:the_regnum)
    assert_raise(RuntimeError,
                 "Should raise a RuntimeError - cannot resolve to a record that is already a duplicate.") do
      Name::AsResolvedTypeahead::ForDuplicateOf.new(
        "", already_a_duplicate.full_name, other_name.id
      )
    end
  end
end
