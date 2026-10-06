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

# InstancesController#typeahead_for_name_showing_references_to_update_instance.
# Answers the shared html fragment to the synonym edit form's cites
# reference field, now on stimulus-autocomplete, and json as before.
class InstTAhead4NameShowRefToUpdSuggestionsTest < ActionDispatch::IntegrationTest
  ROSS = "Ross, E.M., (1986) Flora of South-eastern Queensland. 2:1986"

  def get_suggestions(term, format: :html)
    sign_in_as_fake_user(groups: [ "edit" ]) do
      get typeahead_for_name_showing_references_to_update_instance_path(format: format),
          params: {
            term: term,
            instance_id: instances(:xyz_costata_is_synonym_of_angophora_costata).id,
          }
    end
  end

  def assert_select_in_body(*args, &block)
    assert_select(Nokogiri::HTML::DocumentFragment.parse(response.body),
                  *args, &block)
  end

  test "should get cites reference suggestions as an html fragment" do
    get_suggestions("an")

    assert_response :success
    assert_select_in_body(
      "li.autocomplete-result[data-autocomplete-value]" \
      "[data-autocomplete-label*=?]",
      ROSS
    )
  end

  test "should render a no matches option when nothing matches" do
    get_suggestions("zzzzzz no such citation")

    assert_response :success
    assert_select_in_body "li.autocomplete-result[aria-disabled='true']",
                          text: "No matches"
  end

  test "should still answer json" do
    get_suggestions("an", format: :json)

    assert_response :success
    assert_match ROSS, response.body
  end
end
