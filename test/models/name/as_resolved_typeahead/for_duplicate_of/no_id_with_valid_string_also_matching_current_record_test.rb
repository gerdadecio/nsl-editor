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
# A record can never be a duplicate of itself. The suggestion list
# (Name::AsTypeahead.duplicate_suggestions) already excludes the record
# being edited via avoids_id; this confirms the resolver applies the same
# exclusion when the user types an exact match and saves without picking a
# suggestion, rather than silently resolving to the record itself.
class NameAsResolvedTANoDuplicateOfIdWithValidStringAlsoMatchingCurrentRecord < ActiveSupport::TestCase
  test "no id with valid string also matching current record" do
    name = names(:the_regnum)
    assert_raise(RuntimeError,
                 "Should raise a RuntimeError - cannot be a duplicate of itself.") do
      Name::AsResolvedTypeahead::ForDuplicateOf.new("", name.full_name, name.id)
    end
  end
end
