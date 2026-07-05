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
# require 'sucker_punch/testing/inline'

# Single controller test.
class GenusNameChangeHandlesDoubleParentTest < ActionController::TestCase
  tests NamesController
  setup do
    @grevillea = names(:grevillea_genus)
    @descendant = names(:grevillea_cultivar_hybrid)
    @request.headers["Accept"] = "application/javascript"
    stub_request(:get,
                 "#{resource}833026435/api/name-strings")
      .with(headers: { "Accept" => "*/*",
                       "Accept-Encoding" =>
                       "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
                       "User-Agent" => "Ruby" })
      .to_return(status: 200, body: body, headers: {})
  end

  def body
    '{ "class": "silly name class", "_links": { "permalink": [] },
    "name_element": "redundant name element for id 91755",
    "action": "unnecessary action",
    "result": {
        "fullMarkedUpName": "full marked up name for id 91755",
        "simpleMarkedUpName": "simple marked up name for id 91755",
        "fullName": "full name for id 91755",
        "simpleName": "simple name for id 91755"
    } }'
  end

  def resource
    "http://localhost:9090/nsl/services/name/apni/"
  end

  # Not correctly creating circumstances of a stale record error
  # such as I get in development if I change the name of Grevillea genus.
  test "genus name change without stale record error" do
    skip "Cannot get the suckerpunch job to run in test."
    asserts1
    post_update
    asserts2
  end

  def asserts1
    assert @descendant.parent == @grevillea,
           "Grevillea should be the parent for this test."
    assert @descendant.second_parent == @grevillea,
           "Grevillea should be the second parent for this test."
  end

  def post_update
    post(:update,
         params: { "random_id" => "",
                   "category" => "",
                   "name" => name_hash,
                   "commit" => "Save",
                   "id" => @grevillea.id },
         session: { username: "fred",
                    user_full_name: "Fred Jones",
                    groups: ["edit"] })
  end

  def asserts2
    assert_response :success
    # sleep(2) # to allow for the asynch job
    descendant_after = Name.find(@descendant.id)
    assert @descendant.full_name != descendant_after.full_name,
           "Grevillea's name change should affect the descendant's name."
  end

  def name_hash
    { "name_type_id" => @grevillea.name_type_id,
      "name_rank_id" => @grevillea.name_rank_id,
      "name_status_id" => @grevillea.name_status_id,
      "parent_typeahead" => @grevillea.parent.full_name,
      "parent_id" => @grevillea.parent_id, "name_element" => "XYZ",
      "author_typeahead" => @grevillea.author.abbrev,
      "author_id" => @grevillea.author.id, "sanctioning_author_typeahead" => "",
      "sanctioning_author_id" => "", "duplicate_of_typeahead" => "",
      "duplicate_of_id" => "", "verbatim_rank" => "" }
  end
end
