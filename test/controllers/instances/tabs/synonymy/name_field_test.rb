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

# The synonymy tab's name field is on stimulus-autocomplete, asking for
# instances of names other than the instance's own.
class InstanceSynonymyTabNameFieldTest < ActionDispatch::IntegrationTest
  setup do
    @instance = instances(:triodia_in_brassard)
  end

  def get_tab(tab)
    sign_in_as_fake_user(groups: [ "edit" ]) do
      get instance_tab_path(@instance, tab: tab),
          params: { "row-type" => "instance_record" },
          xhr: true
    end
    assert_response :success
  end

  def assert_name_autocomplete
    assert_select "form#new_instance div.autocomplete[data-controller='autocomplete']" \
                  "[data-autocomplete-url-value='/instances/for_synonymy.html']" \
                  " input#instance-instance-for-name-showing-reference-typeahead" \
                  "[data-autocomplete-target='input'][required]",
                  true
    assert_select "div.autocomplete[data-autocomplete-extra-params-value=?]",
                  { name_id: @instance.name_id }.to_json
    # The hidden cites_id starts empty, so create_cites_and_cited_by still
    # asks for a pick, and is rendered once, by the partial.
    assert_select "div.autocomplete input#instance_cites_id" \
                  "[name='instance[cites_id]']" \
                  "[data-autocomplete-target='hidden']",
                  true
    assert_select "input#instance_cites_id[value]", false
    assert_select "input#instance_cites_id", count: 1
    assert_no_match(/setUpSynonymyInstance\(\)/, response.body)
  end

  test "should render the synonymy tab's name field as a stimulus autocomplete" do
    get_tab("tab_synonymy")
    assert_name_autocomplete
  end

  test "should render the profile v2 synonymy tab's name field as a stimulus autocomplete" do
    get_tab("tab_synonymy_for_profile_v2")
    assert_name_autocomplete
  end
end
