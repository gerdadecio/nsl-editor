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

# Phrase names carry a collector's number, e.g.
#   Dryandra sp. 42 (Three Springs; A.S.George 16789)
# and editors search on it, e.g. "Dryandra%16789" (NSL-5202).
#
# A 4-digit number on its own (between spaces, wildcards or the ends of the
# search) could be a publication year or part of a name, so the typeahead
# offers both. Digits inside a longer number are only ever part of a name.
class ForSynonymyCollectorNumberSearchTest < ActiveSupport::TestCase
  GEORGE_16789_NAMES = [
    "Dryandra sp. 42 (Three Springs; A.S.George 16789)",
    "Dryandra aff. hewardiana (A.S.George 16789)",
    "Dryandra sp. 42 (A.S.George 16789)"
  ].freeze
  # A collector number that looks like a year; its instance is in a 1916
  # reference, while the George 16789 names are in a 1996 one.
  GEORGE_1996_NAME = "Dryandra sp. 7 (A.S.George 1996)"

  # Created here rather than as fixtures: the rank restriction tests list the
  # first 50 results for "*", and more species would push other ranks off
  # that list. Copies of the Darwinia sp. 7 phrase name and its instance,
  # inserted directly so no callbacks reach for Services.
  setup do
    GEORGE_16789_NAMES.each { |full_name| add_phrase_name(full_name, references(:rare_or_threatened_australian_plants)) }
    add_phrase_name(GEORGE_1996_NAME, references(:paper_by_britten_on_angophora))
  end

  def add_phrase_name(full_name, reference)
    name_id = Name.insert!(
      names(:darwinia_sp_7).attributes.except("id").merge(
        "full_name" => full_name,
        "simple_name" => full_name.sub(/ \(.*/, ""),
        "name_element" => full_name.sub(/\ADryandra /, ""),
        "uri" => full_name.parameterize
      ),
      returning: :id
    ).first["id"]
    Instance.insert!(
      instances(:darwinia_sp_7_in_briggs_and_leigh_1996).attributes.except("id").merge(
        "name_id" => name_id,
        "reference_id" => reference.id,
        "uri" => "instance-#{full_name.parameterize}"
      )
    )
  end

  def names_found(terms)
    Instance::AsTypeahead::ForSynonymy.new(terms, names(:a_species).id)
      .results
      .map { |r| r[:value].sub(/ in .*/, "") }
  end

  def assert_finds(expected, terms)
    assert_equal expected.sort, names_found(terms).sort, "Searching for #{terms.inspect}"
  end

  # Collector numbers

  test "collector number joined to a wildcard" do
    assert_finds(GEORGE_16789_NAMES, "Dryandra%16789")
  end

  test "partial collector number between wildcards" do
    assert_finds(GEORGE_16789_NAMES, "Dryandra%1678%")
  end

  test "collector name and number" do
    assert_finds(GEORGE_16789_NAMES, "Dryandra%George%16789")
  end

  test "start of a collector number after the collector's name and a space" do
    assert_finds(GEORGE_16789_NAMES, "Dryandra%George 1678")
  end

  # A space is not a wildcard in this typeahead, so the name is typed out.
  test "collector number of five digits as a separate word" do
    assert_equal [ "Dryandra sp. 42 (A.S.George 16789)" ],
                 names_found("Dryandra sp. 42 (A.S.George 16789")
  end

  # Publication years

  test "a year after the name" do
    assert_finds(GEORGE_16789_NAMES, "Dryandra 1996")
  end

  test "a year before the name" do
    assert_finds(GEORGE_16789_NAMES, "1996 Dryandra")
  end

  test "a year joined to the name with a percent wildcard" do
    assert_finds([ GEORGE_1996_NAME ], "Dryandra%1916")
  end

  test "a year joined to the name with a star wildcard" do
    assert_finds([ GEORGE_1996_NAME ], "Dryandra*1916")
  end

  test "a 4-digit number that matches no year and no name finds nothing" do
    assert_empty names_found("Dryandra 1678")
  end

  # Both at once

  test "a 4-digit number offers both names published that year and names containing it" do
    assert_finds(GEORGE_16789_NAMES + [ GEORGE_1996_NAME ], "Dryandra%1996%")
  end
end
