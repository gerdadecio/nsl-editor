# frozen_string_literal: true

#   Copyright 2015 Australian National Botanic Gardens
#   This file is part of the NSL Editor.
#   Licensed under the Apache License, Version 2.0
#
require "test_helper"

# A loader name match's intended tree parent must be a scientific name,
# whichever path saves it.
class LoaderNameMatchIntendedTreeParentTest < ActiveSupport::TestCase
  setup do
    @match = loader_name_matches(:match_zzz_test_parent_with_match)
  end

  test "should accept a scientific name" do
    @match.intended_tree_parent_name = names(:angophora_costata)

    assert @match.valid?, @match.errors.full_messages.to_sentence
  end

  test "should refuse a name that is not scientific" do
    @match.intended_tree_parent_name = names(:argyle_apple)

    assert_not @match.valid?
    assert_includes @match.errors[:base], "The intended tree parent name must be a scientific name"
  end

  test "should say an id with no name could not be found" do
    @match.intended_tree_parent_name_id = Name.maximum(:id) + 1_000

    assert_not @match.valid?
    assert_includes @match.errors[:base], "The intended tree parent name could not be found"
  end

  test "should give a soft deleted name only the soft deleted error" do
    name = names(:angophora_costata)
    name.update_column(:deleted_at, Time.current)
    @match.intended_tree_parent_name = name

    assert_not @match.valid?
    assert_equal 1, @match.errors[:base].size
    assert_match "has been soft deleted", @match.errors[:base].first
  end

  test "should allow clearing the intended tree parent" do
    @match.intended_tree_parent_name_id = nil

    assert @match.valid?, @match.errors.full_messages.to_sentence
  end

  # Only a change is checked, so an existing value doesn't block other edits.
  test "should not recheck an unchanged intended tree parent" do
    @match.update_column(:intended_tree_parent_name_id, names(:argyle_apple).id)
    @match.reload

    assert @match.valid?, @match.errors.full_messages.to_sentence
  end
end
