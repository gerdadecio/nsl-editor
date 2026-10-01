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

# Single controller test.
#
# NOTE: the original ActionController::TestCase version of this file had a
# `setup` block that issued the request and a set of `asserts`/`asserts1`-
# `asserts8` helper methods, but no `test "..." do` block anywhere that
# called them - so under minitest it registered zero tests and none of this
# ever actually ran. Converting to ActionDispatch::IntegrationTest surfaced
# that dead code, so it has been wired up here:
#   - `groups: ["foa"]` was never a recognized group (see SessionUser -
#     valid groups are edit/admin/QA/treebuilder/taxonomic-review/
#     batch-loader/loader-2-tab), so it granted no tab_profile_v2
#     permission at all. Signing in as fixture user_one ("uone"), who has
#     the draft-profile-editor role for the FOA product, is what actually
#     grants Ability#draft_profile_editor's `can("instances",
#     "tab_profile_v2")`.
#   - asserts6-asserts8 mutate state (product name, product item configs,
#     a Rails.configuration flag) but the original code never re-issued a
#     request afterwards, so they were only ever re-checking the first
#     response. They're now split into their own tests that redo the
#     request after mutating, so the assertions exercise what they claim
#     to.
#   - asserts7's original mutation, `Instance.delete_all`, doesn't drive
#     the "no product configs" condition at all - that message depends on
#     Profile::ProductItemConfig rows for the signed-in user's FOA product
#     (see Profile::ProfileItem::DefinedQuery::ProductAndProductItemConfigs),
#     not on the Instance table - and it would also delete @instance
#     itself, which would make a follow-up request 404/redirect instead of
#     rendering the tab at all. Retargeted to delete the FOA
#     Profile::ProductItemConfig rows instead, which is what actually
#     produces the "no product configs" state.
class InstanceForFoaShowMostTabsTest < ActionDispatch::IntegrationTest
  setup do
    Rails.configuration.profile_v2_aware = true
    @instance = instances(:gaertner_created_metrosideros_costata)
    # Ability#draft_profile_editor only grants :manage_profile (which gates
    # whether the FOA profile tab link renders at all - see
    # app/views/instances/tabs/_all_tab_headings.html.erb) when the instance
    # is a draft. The fixture defaults to draft: false, so it is marked a
    # draft here to satisfy that precondition.
    @instance.update!(draft: true)
    @product_item_config = product_item_config(:ecology_pic)
    @profile_item = profile_item(:ecology_pi)
    # Captured once, before any test can mutate the FOA product (e.g. by
    # renaming it) or its product item configs.
    @foa_context_id = Product.find_by(name: "FOA").context_id
    # Rails.configuration.profile_v2_dropdown_ui is plain mutable global
    # state with no automatic reset between test runs (see asserts8, the
    # only place in this file that changes it) - pin it here so every test
    # in this class starts from a known state instead of depending on
    # whatever it happens to have been left at.
    Rails.configuration.profile_v2_dropdown_ui = false
    show_foa_tab
  end

  test "should show most tabs for foa" do
    asserts1
    asserts2
    asserts3
    asserts4
    asserts5
  end

  test "shows a no product configs message when the profile item's product is not FOA" do
    @product = @profile_item.product
    @product.update(name: "not foa")
    show_foa_tab
    asserts6
  end

  test "shows a no product configs message when there are no product item configs for the product" do
    configs = Profile::ProductItemConfig.where(product_id: @product_item_config.product_id)
    profile_item_ids = Profile::ProfileItem.where(product_item_config_id: configs.select(:id)).pluck(:id)
    # Cascade the deletes manually with delete_all (which skips
    # callbacks) rather than destroy_all: destroy_all triggers
    # Profile::ProfileItem's after_destroy :conditionally_destroy_profile_text,
    # which does `profile_text.destroy if fact?` with no nil guard - a
    # pre-existing bug that raises NoMethodError for any fixture where
    # fact? is true but profile_text is nil (e.g. ecology_pi_ref).
    Profile::ProfileItemAnnotation.where(profile_item_id: profile_item_ids).delete_all
    Profile::ProfileItemReference.where(profile_item_id: profile_item_ids).delete_all
    Profile::ProfileItem.where(id: profile_item_ids).delete_all
    configs.delete_all
    show_foa_tab
    asserts7
  end

  test "toggles the item_type dropdown with profile_v2_dropdown_ui" do
    asserts8
  end

  private

  def show_foa_tab
    # Ability#draft_profile_editor's :manage_profile check also requires a
    # resolved product context (ApplicationController#current_product_from_context)
    # - without it, product_from_context stays nil and the FOA profile tab
    # link never renders. current_context_id is read straight from the
    # session, so it is supplied here via extra_session.
    sign_in_as_fake_user(
      username: "uone",
      full_name: "userx One",
      groups: [],
      extra_session: { current_context_id: @foa_context_id }
    ) do
      get instance_tab_path(id: @instance.id, tab: "tab_profile_v2"),
        headers: { "Accept" => "application/javascript" }
    end
  end

  def asserts1
    assert_response(:success)
    assert_select(
      "a#instance-profile-v2-tab",
      /Profile/
    )
    assert_select(
      "h4",
      @product_item_config.display_html,
      "Should show the product item config display_html"
    )
  end

  def asserts2
    # When viewing the FOA profile tab, the Profile tab li is the one with
    # class "active" - the earlier response body dump confirmed
    # instance-show-tab (Details) renders as "first non-active" while
    # instance-profile-v2-tab renders as "first active". The original
    # assertion here assumed Details was the active tab, which does not
    # match what this request actually renders.
    assert_select(
      "li.active a#instance-profile-v2-tab",
      /Profile/,
      "Shows 'Profile' as the active tab link."
    )
    assert_select(
      "a#instance-show-tab",
      /Details/,
      "Shows 'Details' tab link."
    )
  end

  def asserts3
    assert_select(
      "a#instance-edit-tab",
      false,
      "Does not show 'Edit' tab link."
    )
    assert_select(
      "a#instance-edit-notes-tab",
      false,
      "Does not show 'Notes' tab link."
    )
  end

  def asserts4
    assert_select(
      "a#instance-cite-this-instance-tab",
      false,
      "Does not show 'Syn' tab link."
    )
    assert_select(
      "a#unpublished-citation-tab",
      false,
      "Does not show 'Unpub' tab link."
    )
    assert_select(
      "a#instance-apc-placement-tab",
      false,
      "Should not show 'APC' tab link."
    )
  end

  def asserts5
    # Ability#draft_profile_editor grants can("instances", [..., "tab_comments"])
    # unconditionally, so the Adnot (comments) tab link does show for this
    # role - confirmed in the earlier response body dump. The original
    # assertion had this backwards.
    assert_select(
      "a#instance-comments-tab",
      /Adnot/,
      "Shows 'Adnot' tab link."
    )
    assert_select(
      "a#instance-copy-to-new-reference-tab",
      false,
      "Should not show 'Copy' tab link."
    )
  end

  def asserts6
    assert_response(:success)
    assert_select(
      "a#instance-profile-v2-tab",
      /Profile/
    )
    assert_select(
      "#message_no_product_configs",
      "There are no product or product configs setup yet.",
      "Should show a message"
    )
  end

  def asserts7
    assert_response(:success)
    assert_select(
      "a#instance-profile-v2-tab",
      /Profile/
    )
    assert_select(
      "#message_no_product_configs",
      "There are no product or product configs setup yet.",
      "Should show a message"
    )
  end

  def asserts8
    Rails.configuration.profile_v2_dropdown_ui = true
    show_foa_tab
    assert_select(
      "select#product_item_config_id",
      true
    )
    assert_select(
      "h4",
      false,
      "Should not display profile items immediately"
    )

    Rails.configuration.profile_v2_dropdown_ui = false
    show_foa_tab
    assert_select(
      "select#product_item_config_id",
      false
    )
    assert_select(
      "h4",
      @product_item_config.display_html,
      "Should show the product item config display_html"
    )
  end
end
