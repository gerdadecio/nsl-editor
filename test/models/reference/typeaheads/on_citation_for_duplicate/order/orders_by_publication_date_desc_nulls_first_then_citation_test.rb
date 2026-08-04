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
# NSL-5867 follow-up: results should be ordered by iso_publication_date
# descending, with references that have no date sorted first, then by
# citation. `simple` is ref_type unknown, so no ref_type restriction is
# applied and all three flibbertigibbet (book) fixtures are candidates.
class TAOnCitationForDuplicateOrdersByPublicationDateTest < ActiveSupport::TestCase
  test "ref typeahead on citation for duplicate orders by publication date desc nulls first then citation" do
    typeahead = Reference::AsTypeahead::OnCitationForDuplicate.new(
      "flibbertigibbet",
      references(:simple).id
    )

    ids = typeahead.results.collect { |result| result[:id] }

    assert_equal [references(:flibbertigibbet_no_date).id.to_s,
                  references(:flibbertigibbet_late).id.to_s,
                  references(:flibbertigibbet_early).id.to_s],
                 ids,
                 "Expected no-date reference first (nulls first), then " \
                 "most recently published, then the earliest."
  end
end
