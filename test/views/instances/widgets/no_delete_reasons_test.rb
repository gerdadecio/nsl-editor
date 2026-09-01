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

# app/views/instances/widgets/_no_delete_reasons.html.erb decides, per
# tree_element, whether it is genuinely "detached" (no tree_version_element
# at all) rather than inferring detachment from the tree usage reported by
# TreesHelper#tree_usage_messages. See Instance#allow_delete? / #in_any_tree?
# for why any tree_element at all (attached or not) blocks deletion.
class NoDeleteReasonsPartialTest < ActionView::TestCase
  def render_reasons_for(instance)
    @instance = instance
    render partial: "instances/widgets/no_delete_reasons"
    rendered
  end

  test "a tree_element attached to the current version of a non-accepted tree is not reported as detached" do
    # FOA has accepted_tree: false, but this tree_element's tree_version_element
    # is on the tree's current version, so it is properly attached and must not
    # be mislabelled as detached.
    instance = instances(:invalid_publication_standalone_instance)

    output = render_reasons_for(instance)

    assert_not_includes output, "DETACHED"
  end

  test "a tree_element with no tree_version_element at all is reported as detached" do
    instance = instances(:no_source_system)

    output = render_reasons_for(instance)

    assert_includes output,
                    "Instance is in a DETACHED tree element record for " \
                    "Angophora costata not attached to a tree version."
  end

  test "a detached tree_element is still reported even when another tree_element already gives a normal reason" do
    instance = instances(:casuarina_inophloia_by_mueller_and_bailey)

    output = render_reasons_for(instance)

    assert_includes output, "Instance is in the currently accepted APC tree"
    assert_includes output,
                    "Instance is in a DETACHED tree element record for " \
                    "Casuarina inophloia (detached)."
  end
end
