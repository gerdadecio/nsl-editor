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

# The copy to new reference tab's Reference field is on
# stimulus-autocomplete, asking for references other than the instance's
# current one.
class InstanceCopyToNewReferenceTabReferenceFieldTest < ActionDispatch::IntegrationTest
  setup do
    @instance = instances(:triodia_in_brassard)
  end

  test "should render the reference field as a stimulus autocomplete excluding the current reference" do
    sign_in_as_fake_user(groups: [ "edit" ]) do
      get instance_tab_path(@instance, tab: "tab_copy_to_new_reference"),
          params: { "row-type" => "instance_as_part_of_concept_record" },
          xhr: true
    end

    assert_response :success
    assert_select "form.edit_instance div.autocomplete[data-controller='autocomplete']" \
                  "[data-autocomplete-url-value='/references/typeahead/on_citation/exclude/#{@instance.reference_id}.html']" \
                  " input#instance-reference-typeahead" \
                  "[name='instance[reference_typeahead]']" \
                  "[data-autocomplete-target='input'][required]",
                  true
    # The hidden reference_id starts empty, so the Copy link's
    # must_have_value check waits for a pick, and is rendered once, by the
    # partial.
    assert_select "div.autocomplete input#instance_reference_id" \
                  "[data-autocomplete-target='hidden'][value='']",
                  true
    assert_select "input#instance_reference_id", count: 1
    assert_no_match(/setUpInstanceReferenceExcludingCurrent\(\)/, response.body)
  end
end
