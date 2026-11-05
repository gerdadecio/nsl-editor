# frozen_string_literal: true

#   Copyright 2015 Australian National Botanic Gardens
#   This file is part of the NSL Editor.
#   Licensed under the Apache License, Version 2.0
#
require "test_helper"

# Setting a loader name match's intended taxonomy parent. The field is on
# stimulus-autocomplete, which empties the hidden id whenever the text is
# edited, so a blank id means the text wasn't picked and is refused.
class LoaderNameMatchIntendedTreeParentUpdateTest < ActionDispatch::IntegrationTest
  setup do
    @match = loader_name_matches(:match_zzz_test_parent_with_match)
    @parent = names(:angophora_costata)
  end

  def set_intended_parent(name_id, groups: [ "batch-loader" ])
    sign_in_as_fake_user(groups: groups) do
      patch loader_name_match_path(@match),
        params: {
          commit: "Set Intended Parent",
          loader_name_match: { intended_tree_parent_name_id: name_id },
        },
        headers: { "Accept" => "application/javascript" }
    end
  end

  test "should save the picked intended parent" do
    set_intended_parent(@parent.id)

    assert_response :success
    assert_equal @parent.id, @match.reload.intended_tree_parent_name_id
  end

  test "should refuse text that was not picked from the suggestions" do
    set_intended_parent("")

    assert_response :success
    assert_match "please choose Intended Parent from suggestions", response.body
    assert_nil @match.reload.intended_tree_parent_name_id
  end

  # Whichever check catches it (the cast gives 0, which names nothing), it
  # must not be saved as a clear.
  test "should refuse a non-numeric id rather than clear the parent" do
    @match.update_column(:intended_tree_parent_name_id, @parent.id)
    set_intended_parent("abc")

    assert_match "search-result-details-error-message-container", response.body
    assert_equal @parent.id, @match.reload.intended_tree_parent_name_id
  end

  test "should refuse a name that is not scientific" do
    set_intended_parent(names(:argyle_apple).id)

    assert_match "must be a scientific name", response.body
    assert_nil @match.reload.intended_tree_parent_name_id
  end

  test "should refuse an id with no name" do
    set_intended_parent(Name.maximum(:id) + 1_000)

    assert_match "could not be found", response.body
    assert_nil @match.reload.intended_tree_parent_name_id
  end

  test "should refuse a soft deleted name" do
    @parent.update_column(:deleted_at, Time.current)
    set_intended_parent(@parent.id)

    assert_match "has been soft deleted", response.body
    assert_nil @match.reload.intended_tree_parent_name_id
  end

  test "should clear the intended parent" do
    @match.update_column(:intended_tree_parent_name_id, @parent.id)
    sign_in_as_fake_user(groups: [ "batch-loader" ]) do
      patch loader_name_match_path(@match),
        params: { commit: "Clear Intended Parent", loader_name_match: { id: @match.id } },
        headers: { "Accept" => "application/javascript" }
    end

    assert_response :success
    assert_nil @match.reload.intended_tree_parent_name_id
  end
end
