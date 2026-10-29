# frozen_string_literal: true

#   Copyright 2015 Australian National Botanic Gardens
#   This file is part of the NSL Editor.
#   Licensed under the Apache License, Version 2.0

require "test_helper"

# Name rank scopes work in a data set that uses English rank names (NSL-6003).
class NameScopesEnglishRankNamesTest < ActiveSupport::TestCase
  setup do
    use_english_rank_names
  end

  def rank_names(names)
    names.collect { |name| name.name_rank.name }.uniq
  end

  test "family_name finds names at the family rank" do
    assert_includes(Name.family_name, names(:a_family))
    assert_equal([ "Family" ], rank_names(Name.family_name))
  end

  test "parent_ranks_for_family runs from order down to family" do
    assert_equal([ "Order", "Suborder" ].sort, rank_names(Name.parent_ranks_for_family).sort)
  end

  test "parent_ranks_for_genus runs from family down to genus" do
    assert_equal(
      [ "Family", "Subfamily", "Tribe", "Subtribe" ].sort,
      rank_names(Name.parent_ranks_for_genus).sort,
    )
  end

  test "parent_ranks_for_infrafamily runs from family down to genus" do
    assert_equal(
      [ "Family", "Subfamily", "Tribe", "Subtribe" ].sort,
      rank_names(Name.parent_ranks_for_infrafamily).sort,
    )
  end

  test "parent_ranks_for_infraspecies runs from species down to subform" do
    ranks = rank_names(Name.parent_ranks_for_infraspecies)

    assert_includes(ranks, "Species")
    assert_includes(ranks, "Variety")
    assert_includes(ranks, "Subform")
    assert_not_includes(ranks, "Genus")
  end

  test "ranks_for_unranked runs down to subform, plus unranked names" do
    ranks = rank_names(Name.ranks_for_unranked)

    assert_includes(ranks, "Kingdom")
    assert_includes(ranks, "Family")
    assert_includes(ranks, "Subform")
    assert_includes(ranks, "[unranked]")
  end

  test "but_rank_not_too_high skips tribe when finding the nearest major rank above" do
    ranks = rank_names(Name.joins(:name_rank).but_rank_not_too_high(name_ranks(:genus).id))

    assert_includes(ranks, "Family")
    assert_not_includes(ranks, "Order")
  end
end
