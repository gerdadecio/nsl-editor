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

# The profile v2 tab's Reference field, for adding a reference to a profile
# item, is on stimulus-autocomplete, asking for references by citation.
#
# Signed in and set up as in
# test/controllers/instances/tabs/authorisation/for_foa/show_foa_tab_test.rb,
# which explains why each step is needed for the tab to render.
class InstanceProfileV2TabReferenceFieldTest < ActionDispatch::IntegrationTest
  setup do
    Rails.configuration.profile_v2_aware = true
    Rails.configuration.profile_v2_dropdown_ui = false
    @instance = instances(:gaertner_created_metrosideros_costata)
    @instance.update!(draft: true)
    @profile_item = profile_item(:ecology_pi)
    @foa_context_id = Product.find_by(name: "FOA").context_id
  end

  test "should render the reference field as a stimulus autocomplete" do
    sign_in_as_fake_user(
      username: "uone",
      full_name: "userx One",
      groups: [],
      extra_session: { current_context_id: @foa_context_id }
    ) do
      get instance_tab_path(id: @instance.id, tab: "tab_profile_v2"),
          headers: { "Accept" => "application/javascript" }
    end

    assert_response :success
    assert_select "form.prompt-form-save div.autocomplete[data-controller='autocomplete']" \
                  "[data-autocomplete-url-value='/references/typeahead/on_citation.html']" \
                  " input#instance-reference-typeahead-#{@profile_item.id}" \
                  "[data-autocomplete-target='input'][required][autofocus]" \
                  ":not([name])",
                  true
    # The hidden reference_id keeps its per-item dom id and its
    # un-namespaced param name.
    assert_select "div.autocomplete input#reference-id-hidden-#{@profile_item.id}" \
                  "[name='profile_item_reference[reference_id]']" \
                  "[data-autocomplete-target='hidden']",
                  true
    assert_select "input[name='profile_profile_item_reference[reference_id]']", false
    assert_no_match(/setUpInstanceReferenceProfileV2/, response.body)
  end
end
