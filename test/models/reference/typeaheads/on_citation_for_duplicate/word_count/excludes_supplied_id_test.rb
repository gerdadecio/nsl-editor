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

# Reference model typeahead search.
class TAOnCitationForDuplicateExcludesSuppliedIdTest < ActiveSupport::TestCase
  test "reference typeahead on citation excludes supplied id" do
    reference_to_exclude = references(:adams_paper_in_walsh_book)
    typeahead = Reference::AsTypeahead::OnCitationForDuplicate.new(
      "walsh",
      reference_to_exclude.id
    )
    assert_equal 1, typeahead.results.size, "Should be just one result"
    assert_equal references(:walsh_paper_in_walsh_book).id,
                 typeahead.results.first[:id].to_i,
                 "Unexpected typeahead suggestion."
  end
end
