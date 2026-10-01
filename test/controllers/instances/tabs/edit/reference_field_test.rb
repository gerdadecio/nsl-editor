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

# The instance edit tab's Reference field is on stimulus-autocomplete,
# whichever of its two homes renders it: the standalone update form, when
# the instance has no synonyms, or the change reference widgets, when it
# has.
class InstanceEditTabReferenceFieldTest < ActionDispatch::IntegrationTest
  def get_edit_tab(instance)
    sign_in_as_fake_user(groups: [ "edit" ]) do
      get instance_tab_path(instance, tab: "tab_edit"), xhr: true
    end
    assert_response :success
  end

  def assert_reference_autocomplete(form_selector)
    assert_select "#{form_selector} div.autocomplete[data-controller='autocomplete']" \
                  "[data-autocomplete-url-value='/references/typeahead/on_citation.html']" \
                  " input#instance-reference-typeahead" \
                  "[name='instance[reference_typeahead]']" \
                  "[data-autocomplete-target='input'][required]",
                  true
    assert_select "#{form_selector} div.autocomplete" \
                  " input#instance_reference_id" \
                  "[data-autocomplete-target='hidden']",
                  true
    assert_select "input#instance_reference_id", count: 1
    assert_no_match(/setUpInstanceReference\(\)/, response.body)
  end

  test "should render the update form's reference field as a stimulus autocomplete" do
    instance = instances(:triodia_in_brassard)
    assert instance.update_reference_allowed?

    get_edit_tab(instance)
    assert_reference_autocomplete("form.edit_instance")
    assert_select "form#change-reference-form", false
  end

  test "should render the change reference widgets' field as a stimulus autocomplete" do
    instance = instances(:britten_created_angophora_costata)
    assert_not instance.update_reference_allowed?

    get_edit_tab(instance)
    assert_reference_autocomplete("form#change-reference-form")
    assert_select "input#instance-reference-typeahead" \
                  "[value='#{instance.reference.citation}']",
                  true
  end
end
