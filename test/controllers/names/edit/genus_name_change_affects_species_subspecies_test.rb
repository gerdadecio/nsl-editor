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
class GenusNameChangeAffectsSpAndSubspeciesTest < ActionController::TestCase
  tests NamesController

  test "genus name change affects species and subspecies" do
    skip "Problem with verifying the results of the job in test."
    # By examining logs I can see the correct behaviour is occurring,
    # but the results in the test session do not show the database
    # changes which makes me think there is some sort of database session
    # separation occurring.

    genus = names(:a_genus)
    species = names(:a_species)
    subspecies = names(:a_subspecies)
    @request.headers["Accept"] = "application/javascript"
    post(:update,
         params: { name: { "name_element" => "newname" },
                   id: genus.id },
         session: { username: "fred",
                    user_full_name: "Fred Jones",
                    groups: ["edit"] })
    assert_response :success
    # puts genus.id
    # genus.children.each {|c| puts c.id}
    # genus_afterwards = Name.find(genus.id)
    # puts genus.full_name
    # puts genus_afterwards.full_name
    assert genus.full_name != genus_afterwards.full_name,
           "The genus name should change."
    sleep(2) # to allow for the asynch job
    # puts species.id
    # puts species.parent_id
    species_afterwards = Name.find(species.id)
    # puts species.full_name
    # puts species_afterwards.full_name
    assert species.full_name != species_afterwards.full_name,
           "The genus name change should affect the species' name."
    subspecies_afterwards = Name.find(subspecies.id)
    assert subspecies.full_name != subspecies_afterwards.full_name,
           "The genus name has change should affect the subspecies' name."
  end
end
