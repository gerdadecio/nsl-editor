# frozen_string_literal: true

#   Copyright 2015 Australian National Botanic Gardens
#   This file is part of the NSL Editor.
#   Licensed under the Apache License, Version 2.0

require "test_helper"

# NameRank.names_for and the rank predicates match Latin and English rank names.
class NamesForTest < ActiveSupport::TestCase
  test "adds the English name to a Latin rank name that has one" do
    assert_equal([ "Familia", "Family" ], NameRank.names_for("Familia"))
  end

  test "adds Division to Divisio" do
    assert_equal([ "Divisio", "Division" ], NameRank.names_for("Divisio"))
  end

  test "leaves a rank name with no English equivalent as it is" do
    assert_equal([ "Genus" ], NameRank.names_for("Genus"))
  end

  test "takes several rank names" do
    assert_equal(
      [ "Ordo", "Order", "Genus", "Forma", "Form" ],
      NameRank.names_for("Ordo", "Genus", "Forma"),
    )
  end

  test "rank predicates recognise the Latin and the English name" do
    assert(NameRank.new(name: "Familia").family?, "Familia should be family")
    assert(NameRank.new(name: "Family").family?, "Family should be family")
    assert(NameRank.new(name: "Tribe").infrafamilial?, "Tribe should be infrafamilial")
    assert(NameRank.new(name: "Section").infrageneric?, "Section should be infrageneric")
    assert(NameRank.new(name: "Variety").infraspecific?, "Variety should be infraspecific")
    assert(NameRank.new(name: "Subform").infraspecific?, "Subform should be infraspecific")
  end
end
