# frozen_string_literal: true

#   Copyright 2015 Australian National Botanic Gardens
#   This file is part of the NSL Editor.
#   Licensed under the Apache License, Version 2.0
require "test_helper"

# NSL-6039: the names matching a loader name are ordered by the earliest
# publication date of their primary references, names without a primary
# reference last, then by simple_name and name.id.
class LoaderNameMatchChronologicalOrderTest < ActiveSupport::TestCase
  SIMPLE_NAME = "Chronologia ordinata"

  setup do
    @loader_name = loader_names(:accepted_one)
    @loader_name.update_columns(simple_name: SIMPLE_NAME)
    # Each has a single primary instance, each in a different reference.
    # In name.id order they are metrosideros, angophora, casuarina, triodia.
    @metrosideros = matching_name(:metrosideros_costata_gaertn, "1999")
    @angophora = matching_name(:angophora_costata, "1850")
    @casuarina = matching_name(:casuarina_inophloia, "1901-12-31")
    @triodia = matching_name(:triodia_basedowii, "1875-03")
    @no_primary = names(:unknown_species)
    @no_primary.update_columns(simple_name: SIMPLE_NAME)
  end

  test "orders matches by earliest primary reference date, undated last" do
    assert_equal [ @angophora, @triodia, @casuarina, @metrosideros, @no_primary ].map(&:id),
                 @loader_name.matches.map(&:id)
  end

  test "orders cultivar matches the same way" do
    assert_equal [ @angophora, @triodia, @casuarina, @metrosideros, @no_primary ].map(&:id),
                 @loader_name.matches(type: :cultivar).map(&:id)
  end

  test "sorts more specific dates in the same year or month first" do
    # In name.id order: metrosideros, angophora, casuarina, triodia.
    @metrosideros.primary_instances.first.reference.update_columns(iso_publication_date: "1850")
    @angophora.primary_instances.first.reference.update_columns(iso_publication_date: "1850-03")
    @casuarina.primary_instances.first.reference.update_columns(iso_publication_date: "1850-03-15")
    @triodia.primary_instances.first.reference.update_columns(iso_publication_date: "1850-12")
    assert_equal [ @casuarina, @angophora, @triodia, @metrosideros, @no_primary ].map(&:id),
                 @loader_name.matches.map(&:id)
  end

  test "orders matches with the same date by name id" do
    @metrosideros.primary_instances.first.reference.update_columns(iso_publication_date: "1850")
    assert_equal [ @metrosideros, @angophora, @triodia, @casuarina, @no_primary ].map(&:id),
                 @loader_name.matches.map(&:id)
  end

  test "uses the earliest of several primary references" do
    # Move casuarina's 1901-12-31 primary instance to triodia, so triodia
    # has primary references dated 1875-03 and 1901-12-31, and casuarina
    # has none.
    @casuarina.primary_instances.first.update_columns(name_id: @triodia.id)
    undated = [ @casuarina, @no_primary ].sort_by(&:id)
    assert_equal [ @angophora, @triodia, @metrosideros, *undated ].map(&:id),
                 @loader_name.matches.map(&:id)
  end

  private

  def matching_name(fixture, iso_publication_date)
    name = names(fixture)
    name.update_columns(simple_name: SIMPLE_NAME)
    name.primary_instances.first.reference.update_columns(iso_publication_date: iso_publication_date)
    name
  end
end
