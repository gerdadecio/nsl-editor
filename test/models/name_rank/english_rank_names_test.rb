# frozen_string_literal: true

#   Copyright 2015 Australian National Botanic Gardens
#   This file is part of the NSL Editor.
#   Licensed under the Apache License, Version 2.0

require "test_helper"

# NameRank works in a data set that uses English rank names (NSL-6003).
class EnglishRankNamesTest < ActiveSupport::TestCase
  setup do
    use_english_rank_names
  end

  test "finds the family rank" do
    assert_equal(name_ranks(:familia), NameRank.family)
    assert_equal("Family", NameRank.family.name)
  end

  test "works out which ranks are below family" do
    assert(name_ranks(:genus).below_family?, "Genus should be below family")
    assert_not(name_ranks(:familia).below_family?, "Family should not be below family")
    assert_not(name_ranks(:ordo).below_family?, "Order should not be below family")
  end

  test "splits the rank options at family" do
    above = NameRank.above_family_options.collect(&:first)
    below = NameRank.below_family_options.collect(&:first)

    assert_includes(above, "Order")
    assert_includes(above, "Family")
    assert_not_includes(above, "Genus")
    assert_includes(below, "Subfamily")
    assert_includes(below, "Variety")
    assert_not_includes(below, "Family")
  end

  test "includes the family ranks in the infrafamilial scope" do
    ranks = NameRank.infrafamilial.collect(&:name)

    assert_includes(ranks, "Family")
    assert_includes(ranks, "Tribe")
    assert_not_includes(ranks, "Genus")
  end

  test "a new family-or-above name starts at the family rank" do
    assert_equal(name_ranks(:familia), Name::AsNew.scientific_family_or_above.name_rank)
  end
end
