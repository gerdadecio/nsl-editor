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

# The synonym edit form's cites reference field is on stimulus-autocomplete,
# asking for the other instances of the synonym's name.
class InstanceEditTabCitesReferenceFieldTest < ActionDispatch::IntegrationTest
  setup do
    @instance = instances(:xyz_costata_is_synonym_of_angophora_costata)
  end

  test "should render the cites reference field as a stimulus autocomplete" do
    sign_in_as_fake_user(groups: [ "edit" ]) do
      get instance_tab_path(@instance, tab: "tab_edit"), xhr: true
    end

    assert_response :success
    assert_select "form.edit_instance div.autocomplete[data-controller='autocomplete']" \
                  "[data-autocomplete-url-value='/instances/for_name_showing_reference_to_update_instance.html']" \
                  " input#instance-instance-for-name-showing-reference-typeahead" \
                  "[name='instance[instance_for_name_showing_reference_typeahead]']" \
                  "[data-autocomplete-target='input'][required]" \
                  "[value=?]",
                  @instance.this_cites.reference.citation
    assert_select "div.autocomplete[data-autocomplete-extra-params-value=?]",
                  { instance_id: @instance.id }.to_json
    # The hidden cites_id starts on the instance's current one and is
    # rendered once, by the partial.
    assert_select "div.autocomplete input#instance_cites_id" \
                  "[name='instance[cites_id]']" \
                  "[data-autocomplete-target='hidden']" \
                  "[value='#{@instance.cites_id}']",
                  true
    assert_select "input#instance_cites_id", count: 1
    assert_no_match(/setUpInstanceInstanceForNameShowingReferenceUpdate\(\)/, response.body)
  end
end
