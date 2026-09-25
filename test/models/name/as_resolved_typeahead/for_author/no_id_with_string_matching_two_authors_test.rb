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

# Single name model test.
class NameAsEdNoAuthIdWithStringMatchingTwoAbbrevsTest < ActiveSupport::TestCase
  test "no author id with string matching 2 abbrevs" do
    skip
    # This test became redundant in its present form when a
    # database constraint was added to prevent duplicate author names.
    # I'm leaving it here so when we clean it out we review the code
    # than handles this case in the typeahead - needs refactoring,
    # possibly different type of testing.
    author_1 = authors(:has_matching_abbrev_1)
    assert Author.where(abbrev: author_1.abbrev).size == 2,
      "Should be two Authors with the same abbrev."
    assert_raise(
      RuntimeError,
      "Should raise a RuntimeError for invalid author string.",
    ) do
      Name::AsResolvedTypeahead::ForAuthor.new(
        "",
        author_1.abbrev,
        "Some Author Name",
      )
    end
  end
end
