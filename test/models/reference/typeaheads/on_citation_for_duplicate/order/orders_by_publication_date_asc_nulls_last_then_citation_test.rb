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
# NSL-5789: results should be ordered by iso_publication_date
# ascending (oldest first), with references that have no date sorted last,
# then by citation. `simple` is ref_type unknown, so no ref_type restriction is
# applied and all three flibbertigibbet (book) fixtures are candidates.
class TAOnCitationForDuplicateOrdersByPublicationDateTest < ActiveSupport::TestCase
  test "ref typeahead on citation for duplicate orders by publication date asc nulls last then citation" do
    typeahead = Reference::AsTypeahead::OnCitationForDuplicate.new(
      "flibbertigibbet",
      references(:simple).id
    )

    ids = typeahead.results.collect { |result| result[:id] }

    assert_equal [
      references(:flibbertigibbet_early).id.to_s,
      references(:flibbertigibbet_late).id.to_s,
      references(:flibbertigibbet_no_date).id.to_s
    ],
                 ids,
                 "Expected the earliest reference first, then the later one, " \
                   "then the no-date reference (nulls last)."
  end
end
