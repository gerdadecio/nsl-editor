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

# Loader::Name#set_children_to_new_batch_id (before_save, when loader_batch_id
# changes) moves a loader name's children to the new batch with it.
#
# Bug (findings #8b): it had
#     elsif child.record_type = "misapplied"
# (assignment, not comparison). That calls the child's record_type= setter
# and is always truthy, so every child that is not a synonym was re-typed as
# "misapplied" and then saved with child.save!.
#
# In normal use children are synonyms or misapplieds, so the damage needs a
# child of some other record type (parent_id can be set via Edit Raw). The
# controls check that synonym and misapplied children still move correctly.
#
# Fixtures: zzz_test_parent_no_match (accepted, batch_one) has a synonym child
# (synonym_parent_no_pref_match) and a misapplied child
# (misapp_parent_no_pref_match). A third child of another record type is
# attached with update_columns so no callbacks run during setup.
class LoaderNameMoveToNewBatchChildrenTest < ActiveSupport::TestCase
  setup do
    @parent = loader_names(:zzz_test_parent_no_match)
    @synonym_child = loader_names(:synonym_parent_no_pref_match)
    @misapplied_child = loader_names(:misapp_parent_no_pref_match)
    @other_child = loader_names(:misapp_parent_using_existing)
    @other_child.update_columns(parent_id: @parent.id, record_type: "excluded")
    @new_batch = Loader::Batch.find_by!(name: "Batch Two")
    assert_not_equal @new_batch.id, @parent.loader_batch_id, "Setup: parent starts in another batch"
  end

  def move_parent_to_new_batch
    parent = Loader::Name.find(@parent.id)
    parent.loader_batch_id = @new_batch.id
    parent.save!
  end

  # The case the bug got wrong.
  test "a child that is neither synonym nor misapplied keeps its record type" do
    move_parent_to_new_batch

    assert_equal "excluded", @other_child.reload.record_type,
      "Moving the parent to a new batch must not re-type the child as misapplied"
  end

  # Controls: these already work and must keep working.
  test "a child that is neither synonym nor misapplied still moves to the new batch" do
    move_parent_to_new_batch

    assert_equal @new_batch.id, @other_child.reload.loader_batch_id
  end

  test "a synonym child stays a synonym and moves to the new batch" do
    move_parent_to_new_batch

    @synonym_child.reload
    assert_equal "synonym", @synonym_child.record_type
    assert_equal @new_batch.id, @synonym_child.loader_batch_id
  end

  test "a misapplied child stays misapplied and moves to the new batch" do
    move_parent_to_new_batch

    @misapplied_child.reload
    assert_equal "misapplied", @misapplied_child.record_type
    assert_equal @new_batch.id, @misapplied_child.loader_batch_id
  end
end
