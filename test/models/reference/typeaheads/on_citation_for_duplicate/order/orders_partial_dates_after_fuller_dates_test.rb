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
# NSL-5789: within the same year or month, references with a partial
# iso_publication_date sort after those with a fuller date: a full date,
# then month-only, then year-only. `simple` is ref_type unknown, so no
# ref_type restriction is applied and all the skedaddle (book) fixtures are
# candidates.
class TAOnCitationForDuplicateOrdersPartialDatesAfterFullerDatesTest < ActiveSupport::TestCase
  test "ref typeahead on citation for duplicate orders partial dates after fuller dates" do
    typeahead = Reference::AsTypeahead::OnCitationForDuplicate.new(
      "skedaddle",
      references(:simple).id
    )

    ids = typeahead.results.collect { |result| result[:id] }

    assert_equal [
      references(:skedaddle_1800).id.to_s,
      references(:skedaddle_1900_01_01).id.to_s,
      references(:skedaddle_1900_06_06).id.to_s,
      references(:skedaddle_1900_06).id.to_s,
      references(:skedaddle_1900).id.to_s,
      references(:skedaddle_1990).id.to_s,
      references(:skedaddle_no_date).id.to_s
    ],
                 ids,
                 "Expected full dates before month-only before year-only " \
                   "within the same year, then the no-date reference last."
  end
end
