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

# Name#family_dependents? when a family has exactly one member.
#
# family_members are the names whose family_id points at this family.
# With exactly one member, the family has a dependent unless that one
# member is the family itself.
#
# Bug (findings #8): the method had
#     return false if family_id = id
# (assignment, not comparison). Inside a method that creates a local variable
# rather than calling the family_id= setter, so the record isn't changed, but
# the expression is always truthy: a family whose single member is a
# *different* name was reported as having no dependents.
#
# Fixtures: cyperaceae is a familia whose own family_id is itself, with two
# other members (ptychocaryum_ghaeri, darwinia_sp_7). Each test adjusts
# family_id values with update_column so no callbacks or services run.
class NameFamilyDependentsSingleMemberTest < ActiveSupport::TestCase
  setup do
    @family = names(:cyperaceae)
    @member = names(:ptychocaryum_ghaeri)
    @other_member = names(:darwinia_sp_7)
    assert @family.name_rank.family?, "Test family should have family rank"
  end

  # The case the bug got wrong.
  test "one member that is another name, family's own family_id points elsewhere: has dependents" do
    @other_member.update_column(:family_id, nil)
    @family.update_column(:family_id, names(:proteaceae).id)
    family = Name.find(@family.id)
    assert_equal [ @member.id ], family.family_members.pluck(:id), "Setup: exactly one member, not itself"

    assert family.family_dependents?,
      "A family whose only member is a different name has a dependent"
  end

  # Control: guards against a "fix" that turns the local into self.family_id =.
  test "family_dependents? does not change the family's family_id" do
    @other_member.update_column(:family_id, nil)
    @family.update_column(:family_id, names(:proteaceae).id)
    family = Name.find(@family.id)

    family.family_dependents?

    assert_equal names(:proteaceae).id, family.family_id, "family_id should be unchanged"
    assert_not family.changed?, "family_dependents? should not modify the record"
  end

  # Controls: branches that were already right and must stay right.
  test "one member that is the family itself: no dependents" do
    @member.update_column(:family_id, nil)
    @other_member.update_column(:family_id, nil)
    family = Name.find(@family.id)
    assert_equal [ @family.id ], family.family_members.pluck(:id), "Setup: the only member is itself"

    assert_not family.family_dependents?
  end

  test "one member that is another name, family's own family_id blank: has dependents" do
    @other_member.update_column(:family_id, nil)
    @family.update_column(:family_id, nil)
    family = Name.find(@family.id)
    assert_equal [ @member.id ], family.family_members.pluck(:id), "Setup: exactly one member, not itself"

    assert family.family_dependents?
  end

  test "more than one member: has dependents" do
    family = Name.find(@family.id)
    assert_operator family.family_members.count, :>, 1, "Setup: several members"

    assert family.family_dependents?
  end
end
