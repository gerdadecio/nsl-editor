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

# Companion to self_citation_via_exact_text_match_is_rejected_test.rb -
# checks the context_name_id exclusion added to
# Name::AsResolvedTypeahead::ForUnpubCitationInstance#text_only_case_sensitive_equals
# only excludes the citing instance's own name, not names in general.
# An exact text match for a genuinely different name must still succeed
# even though a context_name_id is present on the request.
class InstancesCreateCitedByTextMatchNotExcludedTest < ActionController::TestCase
  tests InstancesController

  def setup
    @cited_by = instances(:gaertner_created_metrosideros_costata)
    @name = names(:argyle_apple)
    @request.headers["Accept"] = "application/javascript"
  end

  test "exact text match for a different name still succeeds with context_name_id set" do
    assert_not_equal @name.id, @cited_by.name.id,
                      "Fixture sanity check: target name and context name must differ"

    assert_difference("Instance.count") do
      post(:create_cited_by,
           params: { instance: { "name_typeahead" => @name.full_name,
                                 "name_id" => "",
                                 "context_name_id" => @cited_by.name.id,
                                 "page" => "",
                                 "reference_id" => @cited_by.reference.id,
                                 "cited_by_id" => @cited_by.id,
                                 "cites_id" => "",
                                 "instance_type_id" => instance_types(:common_name) } },
           session: { username: "fred", user_full_name: "Fred Jones", groups: ["edit"] })
    end

    assert_equal @name.id, assigns(:instance).name_id
  end
end
