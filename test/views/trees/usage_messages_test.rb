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

# app/views/trees/_usage_messages.html.erb is shared by the instance and name
# delete tabs, so it has to name the trees for whichever record it is given.
# The current/draft/historical split itself is covered by
# spec/helpers/trees_helper_spec.rb, where drafts and superseded versions can
# be built; the fixtures only have current versions.
class TreeUsageMessagesPartialTest < ActionView::TestCase
  def render_messages_for(record)
    render partial: "trees/usage_messages", locals: {record: record}
    rendered
  end

  test "names the trees an instance is currently accepted in" do
    output = render_messages_for(instances(:casuarina_inophloia_by_mueller_and_bailey))

    assert_includes output, "Instance is in the currently accepted APC tree."
  end

  test "names every tree a name is currently accepted in" do
    # Angophora costata is on the current version of both APC and FOA.
    output = render_messages_for(names(:angophora_costata))

    assert_includes output, "Name is in the currently accepted APC, FOA trees."
  end

  test "says nothing for a record that is in no tree" do
    output = render_messages_for(names(:metrosideros_costata))

    assert_equal "", output.strip
  end
end
