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

# Single controller test.
# You need to identify a specific name for an unpublished citation.
# If you send only text, then you have to either exact-match 1 name or
# wildcard-match 1 name.
class InstancesCreateCitedByWWCNameTextMatch2Test < ActionController::TestCase
  tests InstancesController
  def setup
    @cited_by = instances(:gaertner_created_metrosideros_costata)
    @name = names(:argyle_apple)
    @request.headers["Accept"] = "application/javascript"
  end

  test "cannot create unpub citation for wildcard name matching 2 or more" do
    assert_no_difference("Instance.count") do
      post(:create_cited_by,
           params: { instance: { "name_typeahead" => "a",
                                 "name_id" => "",
                                 "page" => "",
                                 "reference_id" => @cited_by.reference.id,
                                 "cited_by_id" => @cited_by.id,
                                 "cites_id" => "",
                                 "instance_type_id" => instance_types(:common_name) } },
           session: { username: "fred", user_full_name: "Fred Jones", groups: ["edit"] })
    end
  end
end
