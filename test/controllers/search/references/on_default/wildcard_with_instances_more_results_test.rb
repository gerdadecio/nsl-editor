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

# Regression test for the limit/total redesign, using a "*" default
# search to match many references at once (rather than the usual
# id:/citation:/title: single-reference fixtures used elsewhere) so at
# least one matching reference genuinely has instances attached - a
# single-reference match can only ever have total == 1, which can't
# meaningfully exercise "N records" for N > 1, or prove instances aren't
# silently inflating the count.
#
# "*" becomes "%%" once the default reference search's citation-token:
# rule (trailing_wildcard: true, plus the value's own "*" -> "%") is
# applied - a citation LIKE that matches every reference with a
# citation - so this matches most/all of the ~119 reference fixtures.
#
# NOTES (test fix): an earlier version of this test used a small
# limit:5, expecting one of the first 5 references (in citation order)
# to have attached instances - but ordering by citation is alphabetical,
# and none of the fixtures that sort first happen to have any. Using a
# limit comfortably larger than the whole reference fixture set (~119)
# instead guarantees every matching reference - including
# bucket_reference_for_default_instances, with 36 attached instances -
# is included, without having to know or guess the exact match count or
# sort position of any one fixture.
class SearchRefsOnDefaultWildcardWithInstancesMoreResultsTest < ActionController::TestCase
  tests SearchController

  test "'*' with show-instances: reports references only, not instances, even unlimited" do
    get(:search,
        params: { query_target: "reference",
                  query_string: "* show-instances: limit:500" },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: [] })
    assert_response :success

    summary_text = nil
    assert_select "#search-results-summary" do |elements|
      summary_text = elements.first.text
    end
    match = summary_text.match(/(\d+) records?\b/)
    assert match, "Expected \"N record(s)\", got: #{summary_text.strip}"
    count = match[1].to_i

    # Sanity check this is actually matching many references, not
    # accidentally falling back to some narrower/empty match.
    assert_operator count, :>, 50,
                     "Expected '*' to match most of the reference " \
                     "fixtures - got: #{summary_text.strip}"

    # Real instance rows are rendered (proves instances are genuinely
    # present in this result set, not just theoretically)...
    assert_select "tr.instance-within-reference-record" do |elements|
      assert_operator elements.size, :>, 0,
                       "Expected at least one attached instance row to be rendered"
    end

    # ...but the reported count is references only, not references+
    # instances combined - this is the original bug: "pl si: limit: 600"
    # reported "4443 of 6755 records", where 4443 was references+
    # instances combined rather than the 600 references actually
    # returned. tr.search-result covers every result row, reference or
    # instance, so it should comfortably exceed the reported count.
    total_row_count = css_select("tr.search-result").size
    assert_operator total_row_count, :>, count,
                     "Expected more rendered rows (references+instances) " \
                     "than the reported record count (#{count}) - got " \
                     "#{total_row_count} rows"
  end
end
