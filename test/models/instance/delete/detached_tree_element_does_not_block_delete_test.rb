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

# Regression test for a real (rare) data state: an instance can be linked to
# a tree_element that is itself not attached to any tree_version (i.e. there
# is no tree_version_element pointing at it). The tree_join_v view - built by
# joining tree -> tree_version -> tree_version_element -> tree_element -
# cannot see such a tree_element.
#
# Instance#in_any_tree? (and so #allow_delete?) is backed by tree_join_v, so
# a detached tree_element is not counted as tree usage and does not, on its
# own, stop the editor from offering a delete. The database foreign key from
# tree_element to instance still exists, which is why
# app/views/instances/widgets/_no_delete_reasons.html.erb checks
# @instance.tree_elements directly and reports the DETACHED record.
class DetachedTreeElementDoesNotBlockDeleteTest < ActiveSupport::TestCase
  test "the fixture tree_element really has no tree_version_element" do
    tree_element = tree_elements(:tree_element_not_attached_to_a_tree_version)

    assert tree_element.tree_version_elements.empty?,
      "fixture should not be attached to any tree_version"
  end

  test "instance is not visible via tree_join_v" do
    instance = instances(:no_source_system)

    assert instance.tree_join_v.empty?,
      "tree_join_v should not see a tree_element with no tree_version_element"
  end

  test "instance is still found via the tree_elements association" do
    instance = instances(:no_source_system)

    assert_includes instance.tree_elements, tree_elements(:tree_element_not_attached_to_a_tree_version)
  end

  test "in_any_tree? is false because the tree_element is not in tree_join_v" do
    instance = instances(:no_source_system)

    assert_not instance.in_any_tree?,
      "in_any_tree? should not count a tree_element that is not in tree_join_v"
  end

  test "in_any_tree? is true for a tree_element that is attached to a tree version" do
    instance = instances(:instance_for_name_in_taxonomy)

    assert instance.in_any_tree?
  end

  test "allow_delete? is not blocked by the detached tree_element" do
    instance = instances(:no_source_system)

    assert instance.allow_delete?,
      "a detached tree_element alone should not stop a delete being offered"
  end
end
