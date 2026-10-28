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

# InstancesController#typeahead_for_product_item_config. Answers the shared
# html fragment to the profile v2 link a published profile item field, now
# on stimulus-autocomplete, and json, as before, to any other format.
class InstancesTypeaheadForProductItemConfigSuggestionsForEditorTest < ActionDispatch::IntegrationTest
  setup do
    # Only published facts are offered for linking.
    @profile_item = profile_item(:ecology_pi)
    @profile_item.update_columns(is_draft: false)
    @instance = @profile_item.instance
  end

  def get_suggestions(term, format: :html, product_item_config_id: @profile_item.product_item_config_id)
    sign_in_as_fake_user(groups: [ "edit" ]) do
      get typeahead_for_product_item_config_path(format: format),
          params: { term: term, product_item_config_id: product_item_config_id }
    end
  end

  def assert_select_in_body(*args, &block)
    assert_select(Nokogiri::HTML::DocumentFragment.parse(response.body),
                  *args, &block)
  end

  # The profile item id is what link_profile_item_controller.js fetches
  # the details of on a pick.
  test "should get suggestions as an html fragment carrying the profile item id" do
    get_suggestions(@instance.name.full_name)

    assert_response :success
    assert_select_in_body(
      "li.autocomplete-result[data-autocomplete-value='#{@instance.id}']" \
      "[data-profile-item-id='#{@profile_item.id}']" \
      "[data-autocomplete-label^=?]",
      "#{@instance.name.full_name} in "
    )
  end

  test "should render a no matches option without a product item config" do
    get_suggestions(@instance.name.full_name, product_item_config_id: "")

    assert_response :success
    assert_select_in_body "li.autocomplete-result[aria-disabled='true']",
                          text: "No matches"
  end

  test "should still answer json" do
    get_suggestions(@instance.name.full_name, format: :json)

    assert_response :success
    assert_includes JSON.parse(response.body).pluck("profile_item_id"), @profile_item.id
  end

  # What the endpoint answered before html was added, kept for any caller
  # that asks for neither json nor html.
  test "should answer json to any other format" do
    sign_in_as_fake_user(groups: [ "edit" ]) do
      get typeahead_for_product_item_config_path,
          params: { term: @instance.name.full_name, product_item_config_id: @profile_item.product_item_config_id },
          headers: { "Accept" => "application/javascript" }
    end

    assert_response :success
    assert_includes JSON.parse(response.body).pluck("id"), @instance.id
  end
end
