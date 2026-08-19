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

# Regression test for the text-only fallback path: if the typeahead's
# hidden name_id field never gets set (e.g. JS fails, or the user types
# an exact name and submits without picking from the dropdown), the
# controller falls back to resolving the name from the raw typed text -
# see Name::AsResolvedTypeahead::ForUnpubCitationInstance#text_only_case_sensitive_equals.
# That fallback used to have no concept of "the name to exclude" at all,
# so typing the citing instance's own exact full name would resolve
# straight back to itself - the same self-citation bug as
# context_name_id_is_not_used_as_selected_name_test.rb, via a different
# route. context_name_id now excludes the citing instance's own name from
# that text match too, so this should be rejected rather than silently
# creating a self-citation.
class InstancesCreateCitedBySelfTextMatchRejectedTest < ActionController::TestCase
  tests InstancesController

  def setup
    @cited_by = instances(:gaertner_created_metrosideros_costata)
    @request.headers["Accept"] = "application/javascript"
  end

  test "typing the citing instance's own exact name is rejected, not self-cited" do
    assert_no_difference("Instance.count") do
      post(:create_cited_by,
           params: { instance: { "name_typeahead" => @cited_by.name.full_name,
                                 "name_id" => "",
                                 "context_name_id" => @cited_by.name.id,
                                 "page" => "",
                                 "reference_id" => @cited_by.reference.id,
                                 "cited_by_id" => @cited_by.id,
                                 "cites_id" => "",
                                 "instance_type_id" => instance_types(:common_name) } },
           session: { username: "fred", user_full_name: "Fred Jones", groups: ["edit"] })
    end

    assert_match(/No case-sensitive exact match/, assigns(:message))
  end
end
