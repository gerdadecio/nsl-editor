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

# Duplicate suggestions are ordered by rank, then by full name.
class NameDuplicateSuggestionsSortOrderTest < ActiveSupport::TestCase
  # The sortcheck fixtures are arranged so that ordering by rank gives the
  # reverse of ordering by full name, so an alphabetical-only sort fails here.
  test "name duplicate suggestions are sorted by rank then full name" do
    suggestions = Name::AsTypeahead.duplicate_suggestions("sortcheck", 0)
    assert(suggestions.is_a?(Array), "suggestions should be an array")
    assert_equal(["Sortcheck zeta", "Sortcheck mu",
                  "Sortcheck alpha", "Sortcheck delta"],
                 full_names_from(suggestions),
                 "Suggestions should be ordered familia, genus, then species " \
                 "with the two species in full name order")
  end

  test "name duplicate suggestions are not sorted by full name alone" do
    suggestions = Name::AsTypeahead.duplicate_suggestions("sortcheck", 0)
    full_names = full_names_from(suggestions)
    refute_equal(full_names.sort, full_names,
                 "Suggestions should be ordered by rank first, not purely " \
                 "alphabetically")
  end

  private

  def full_names_from(suggestions)
    suggestions.collect { |suggestion| suggestion[:value].split(" | ").first }
  end
end
