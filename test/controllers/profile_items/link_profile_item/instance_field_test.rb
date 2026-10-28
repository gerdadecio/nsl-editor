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

# The profile v2 link a published profile item field, rendered for each
# product item config the instance has no profile text for yet, is on
# stimulus-autocomplete, asking for instances with a published profile item
# of the same config.
class ProfileItemsLinkProfileItemInstanceFieldTest < ActionDispatch::IntegrationTest
  setup do
    @original_profile_v2_aware = Rails.configuration.profile_v2_aware
    Rails.configuration.profile_v2_aware = true
    # No profile item of its own for ecology_pic, so the link field shows.
    @instance = instances(:britten_created_angophora_costata)
    @product_item_config = product_item_config(:ecology_pic)
  end

  teardown do
    Rails.configuration.profile_v2_aware = @original_profile_v2_aware
  end

  test "should render the instance field as a stimulus autocomplete" do
    sign_in_as_fake_user(
      username: "uone",
      full_name: "userx One",
      groups: [ "edit", "foa" ],
      extra_session: { current_context_id: Product.find_by(name: "FOA").context_id }
    ) do
      get profile_items_path(instance_id: @instance.id, product_item_config_id: @product_item_config.id),
          headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    assert_response :success
    pic_id = @product_item_config.id
    assert_select "div.link-profile-item-container-#{pic_id}[data-controller='link-profile-item']" \
                  "[data-action='autocomplete.change->link-profile-item#showDetails input->link-profile-item#clearDetails']" \
                  "[data-link-profile-item-details-url-value=?]",
                  "/profile_items/PROFILE_ITEM_ID/details?instance_id=#{@instance.id}"
    assert_select "div.autocomplete[data-controller='autocomplete']" \
                  "[data-autocomplete-url-value='/instances/for_product_item_config.html']" \
                  " input#instance-product-item-config-typeahead-#{pic_id}" \
                  "[data-autocomplete-target='input'][required][autofocus]" \
                  ":not([name])",
                  true
    assert_select "div.autocomplete[data-autocomplete-extra-params-value=?]",
                  { product_item_config_id: pic_id }.to_json
    assert_select "div.autocomplete input#link-profile-item-instance-id-#{pic_id}" \
                  "[data-autocomplete-target='hidden']",
                  true
    assert_no_match(/setUpInstanceForProductItemConfig/, response.body)
  end
end
