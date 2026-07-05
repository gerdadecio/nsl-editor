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
class InstTAhead4NameShowRefToUpdSynonymy4EditTest < ActionController::TestCase
  tests InstancesController

  ROSS = "Ross, E.M., (1986) Flora of South-eastern Queensland. 2:1986"
  FIN = "De Fructibus et Seminibus Plantarum. 1:1788  [invalid publication]"

  FCOMB = "De Fructibus et Seminibus Plantarum. 1:1788  [comb. nov.]"
  JOB = "Journal of Botany, British and Foreign. 54:1916  [basionym]"

  test "editor should be able to typehead for synonymy instance" do
    instance = instances(:xyz_costata_is_synonym_of_angophora_costata)
    @request.headers["Accept"] = "application/javascript"
    get(:typeahead_for_name_showing_references_to_update_instance,
        params: { term: "an",
                  instance_id: instance.id },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: ["edit"] })
    assert response.body.length > 2, "Search should have results."
    assert_match FIN, response.body, "Missing: #{FIN}"
    assert_match FCOMB, response.body, "Missing: #{FCOMB}"
    assert_match JOB, response.body, "Missing: #{JOB}"
    assert_match ROSS, response.body, "Missing: #{ROSS}"
    assert_response :success
  end
end
