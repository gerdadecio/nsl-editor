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

# When a reference has no iso_publication_date of its own, results should
# sort as if it had its parent reference's iso_publication_date - but only
# when the reference's ref_type has use_parent_details set. This mirrors
# the existing db function ref_parent_date() (see db/structure.sql), which
# Instance::AsTypeahead::ForSynonymy's ordering now reuses.
#
# The search below is run against names(:a_classis) - an above-family rank
# that restrict_ranks doesn't filter at all - purely so this test doesn't
# depend on rank restriction behaviour. fallback_reference_date_name (the
# shared name of all four fixture instances) is itself ranked "classis"
# for the same reason: it keeps these fixtures out of the broad "*"
# wildcard searches used by the infraspecific/infrafamilial rank-
# restriction tests elsewhere, which are sensitive to the exact set of
# results returned within Instance::AsTypeahead::ForSynonymy::SEARCH_LIMIT.
class ForSynonymyReferenceParentDateFallbackTest < ActiveSupport::TestCase
  def search
    Instance::AsTypeahead::ForSynonymy.new("Fallbackia parentdatensis",
                                           names(:a_classis).id)
  end

  def value_index(values, marker)
    values.index { |v| v.include?(marker) }
  end

  test "all four fixture instances are found" do
    values = search.results.collect { |r| r[:value] }

    assert value_index(values, "Fallback Ungated Child Reference With No Own Date"),
           "Should include the ungated no-date instance."
    assert value_index(values, "Fallback Earlier Reference"),
           "Should include the 1700 instance."
    assert value_index(values, "Fallback Child Reference With No Own Date"),
           "Should include the instance whose reference has no own date."
    assert value_index(values, "Fallback Later Reference"),
           "Should include the 1980 instance."
  end

  test "a reference with no own date sorts by its parent reference's date " \
       "when its ref_type uses parent details" do
    values = search.results.collect { |r| r[:value] }

    earlier_index = value_index(values, "Fallback Earlier Reference")
    fallback_index = value_index(values, "Fallback Child Reference With No Own Date")
    later_index = value_index(values, "Fallback Later Reference")

    assert earlier_index < fallback_index,
           "The 1700 instance should sort before the instance falling " \
           "back to its parent's 1850 date."
    assert fallback_index < later_index,
           "The instance falling back to its parent's 1850 date should " \
           "sort before the 1980 instance."
  end

  test "a reference with no own date does NOT borrow its parent's date " \
       "when its ref_type does not use parent details" do
    values = search.results.collect { |r| r[:value] }

    ungated_index = value_index(values, "Fallback Ungated Child Reference With No Own Date")
    earlier_index = value_index(values, "Fallback Earlier Reference")

    assert ungated_index < earlier_index,
           "A reference with no date, and a ref_type that does not use " \
           "parent details, should sort as if it had no date at all - " \
           "i.e. before the 1700 instance, not alongside the 1850 parent."
  end

  test "the instance's own citation, not the parent's, is displayed" do
    value = search.results
                  .collect { |r| r[:value] }
                  .find { |v| v.include?("Fallback Child Reference With No Own Date") }

    assert value.present?, "Should include the fallback child instance."
    assert_includes value, "Fallback Child Reference With No Own Date",
                     "Should display the reference's own citation."
    refute_includes value, "Fallback Parent Reference",
                     "Should not display the parent reference's citation " \
                     "- the fallback only affects sort order."
  end
end
