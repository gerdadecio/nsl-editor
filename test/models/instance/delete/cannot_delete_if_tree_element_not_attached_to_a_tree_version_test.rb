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

# Regression test for a real production bug: an instance can be linked to a
# tree_element that is itself not attached to any tree_version (i.e. there
# is no tree_version_element pointing at it). The database foreign key from
# tree_element to instance still blocks deletion, but the tree_join_v view
# -- which is built by joining tree -> tree_version -> tree_version_element
# -> tree_element -- cannot see this tree_element, so any check based on
# tree_join_v alone misses it.
#
# Instance#allow_delete? / #in_any_tree? query tree_element directly and so
# already caught this ("You cannot delete this instance" was shown), but
# the reasons listed in
# app/views/instances/widgets/_no_delete_reasons.html.erb used to rely only
# on tree_join_v and so showed no reason at all. That view now also checks
# @instance.tree_elements directly.
class CannotDeleteIfTreeElementNotAttachedToATreeVersionTest < ActiveSupport::TestCase
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

  test "allow_delete? is false because in_any_tree? finds the tree_element directly" do
    instance = instances(:no_source_system)

    assert instance.in_any_tree?,
           "in_any_tree? should find the tree_element even though it is not in tree_join_v"
    assert_not instance.allow_delete?
  end
end
