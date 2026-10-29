# frozen_string_literal: true

#   Copyright 2015 Australian National Botanic Gardens
#   This file is part of the NSL Editor.
#   Licensed under the Apache License, Version 2.0

require "test_helper"

# The fixtures name the division rank in English. Some data sets still use the
# Latin Divisio, and the rank scopes must treat it the same (NSL-6003).
class NameScopesLatinDivisioRankNameTest < ActiveSupport::TestCase
  setup do
    name_ranks(:division).update!(name: "Divisio")
  end

  def rank_names(names)
    names.collect { |name| name.name_rank.name }.uniq
  end

  test "but_rank_not_too_high skips divisio when finding the nearest major rank above" do
    ranks = rank_names(Name.joins(:name_rank).but_rank_not_too_high(name_ranks(:classis).id))

    assert_includes(ranks, "Regnum")
    assert_includes(ranks, "Divisio")
  end
end
