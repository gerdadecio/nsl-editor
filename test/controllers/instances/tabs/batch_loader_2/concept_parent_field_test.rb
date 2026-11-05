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

# The instance Loader 2 tab's Concept/Parent field is on stimulus-autocomplete,
# reading the batch from the tab's Batch select at query time.
class InstanceBatchLoader2TabConceptParentFieldTest < ActionDispatch::IntegrationTest
  setup do
    @instance = instances(:triodia_in_brassard)
    @was_batch_loader_aware = Rails.configuration.try("batch_loader_aware")
    Rails.configuration.batch_loader_aware = true
  end

  teardown do
    Rails.configuration.batch_loader_aware = @was_batch_loader_aware
  end

  test "should render the concept parent field as a stimulus autocomplete" do
    sign_in_as_fake_user(groups: [ "edit", "batch-loader" ]) do
      get instance_tab_path(@instance, tab: "tab_batch_loader_2"),
          params: { "row-type" => "instance_as_part_of_concept_record" },
          xhr: true
    end

    assert_response :success
    url = loader_names_parent_suggestions_path(format: :html)
    assert_select "div.autocomplete[data-controller='autocomplete']" \
                  "[data-autocomplete-url-value='#{url}'] " \
                  "input#loader-name-parent-typeahead[data-autocomplete-target='input']" \
                  "[name='loader_name[parent_typeahead]'][required]",
                  true
    assert_select "div.autocomplete[data-autocomplete-live-params-value=?]",
                  { loader_batch_id: "loader_batch_id" }.to_json
    assert_select "select#loader_batch_id", true
    assert_select "div.autocomplete input#loader_name_parent_id" \
                  "[data-autocomplete-target='hidden'][value='']",
                  true
    assert_no_match(/setUpLoaderNameParentTypeahead|useSelectedBatch/, response.body)
  end
end
