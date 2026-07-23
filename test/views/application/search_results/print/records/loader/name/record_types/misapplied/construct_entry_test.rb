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
require "ostruct"

# app/views/application/search_results/print/records/loader/name/record_types/
# misapplied/_construct_entry.html.erb sorts a misapplied name's
# preferred_matches by their reference's iso_publication_date.
#
# Regression coverage for jira 5603: iso_publication_date is a nullable
# string column on Reference, so a bare `x.instance.reference.iso_publication_date
# <=> y...` blew up with "comparison of Loader::Name::Match with
# Loader::Name::Match failed" whenever one side was nil (nil <=> anything is
# nil, and a sort block returning nil raises). A first fix attempt added
# `|| '0000-00-00'` but without parentheses, which - because <=> binds tighter
# than || in Ruby - didn't actually change the grouping and could still
# raise. The real fix parenthesises each side before comparing.
#
# These doubles only implement the handful of methods the partial actually
# calls (instance/reference/relationship_instance_type et al) - no fixtures
# needed, since nothing here touches the database.
class MisappliedConstructEntryPartialTest < ActionView::TestCase
  def build_match(citation:, page:, iso_publication_date:)
    reference = OpenStruct.new(citation: citation,
                                iso_publication_date: iso_publication_date)
    instance = OpenStruct.new(reference: reference, page: page)
    OpenStruct.new(
      instance: instance,
      relationship_instance_type: OpenStruct.new(pro_parte?: false),
      name: OpenStruct.new(authorship_extracted: "Extracted Author")
    )
  end

  def build_search_result(matches)
    OpenStruct.new(
      misapp_html: nil,
      doubtful?: false,
      record_type: "misapplied",
      simple_name: "Testia testa",
      name_status: nil,
      preferred_matches: matches
    )
  end

  def render_entry_for(matches)
    render partial: "application/search_results/print/records/loader/name/" \
                     "record_types/misapplied/construct_entry",
           locals: { search_result: build_search_result(matches) }
    rendered
  end

  test "renders without raising when one match's reference has no iso_publication_date" do
    dated = build_match(citation: "Smith, Flora of Nowhere",
                         page: "12",
                         iso_publication_date: "2005-01-01")
    undated = build_match(citation: "Jones, Undated Flora",
                           page: "3",
                           iso_publication_date: nil)

    output = render_entry_for([dated, undated])

    assert_includes output, "Smith, Flora of Nowhere: 12"
    assert_includes output, "Jones, Undated Flora: 3"
  end

  test "renders without raising when both matches' references have no iso_publication_date" do
    undated_a = build_match(citation: "First Undated", page: "1", iso_publication_date: nil)
    undated_b = build_match(citation: "Second Undated", page: "2", iso_publication_date: nil)

    output = render_entry_for([undated_a, undated_b])

    assert_includes output, "First Undated: 1"
    assert_includes output, "Second Undated: 2"
  end

  test "sorts a match with no iso_publication_date before a dated match" do
    dated = build_match(citation: "Later Reference",
                         page: "5",
                         iso_publication_date: "2010-03-04")
    undated = build_match(citation: "Undated Reference",
                           page: "9",
                           iso_publication_date: nil)

    # Deliberately passed in with the dated match first, so a correct result
    # here can only come from the sort, not from input order.
    output = render_entry_for([dated, undated])

    assert output.index("Undated Reference") < output.index("Later Reference"),
           "Expected the undated match to sort before the dated one, got: #{output}"
  end
end
