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

# Regression test for a bug where the hidden field that the name typeahead
# writes the user's selection into, and the field holding the name to
# *exclude* from suggestions (the citing instance's own name - see
# NSL-3215), were the same DOM element. A stale id meant the typeahead's
# selection never actually reached that field, so the form always
# submitted the citing instance's own name - creating an unpublished
# citation from a name to itself instead of to the name the user picked.
#
# The fix splits these into two independent params: name_id (the user's
# selection, submitted and used to build the instance) and
# context_name_id (only used to build the typeahead's exclude-self
# search query). This test locks in that they stay independent - whatever
# context_name_id carries must never end up as the created instance's
# name.
class InstancesCreateCitedByContextNameIdIgnoredTest < ActionController::TestCase
  tests InstancesController

  def setup
    @cited_by = instances(:gaertner_created_metrosideros_costata)
    @selected_name = names(:argyle_apple)
    @request.headers["Accept"] = "application/javascript"
  end

  test "created instance uses the selected name_id, not context_name_id" do
    context_name = @cited_by.name

    assert_not_equal @selected_name.id, context_name.id,
                      "Fixture sanity check: selected name and context name must differ"

    assert_difference("Instance.count") do
      post(:create_cited_by,
           params: { instance: { "name_id" => @selected_name.id,
                                 "context_name_id" => context_name.id,
                                 "name_typeahead" => "",
                                 "page" => "",
                                 "reference_id" => @cited_by.reference.id,
                                 "cited_by_id" => @cited_by.id,
                                 "cites_id" => "",
                                 "instance_type_id" => instance_types(:common_name) } },
           session: { username: "fred", user_full_name: "Fred Jones", groups: ["edit"] })
    end

    created = assigns(:instance)
    assert_equal @selected_name.id, created.name_id,
                 "Should use the selected name, not the context/self name"
    assert_not_equal context_name.id, created.name_id,
                      "Must not silently fall back to citing the name from itself"
  end
end
