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
load "test/models/search/users.rb"

# Single Search model test for Reference target.
#
# In May 2025 I switched from 'english' to 'simple' dictionary and this search
# stopped finding "Hooker's", because the 'simple' dictionary splits
# "Hooker's" into "hooker" and "s", so "hookers" didn't match.
#
# From pg_search 2.4.0, scopes that ignore accents (as search_citation_text_for
# does) strip apostrophes from the citation as well as from the query, so
# "Hooker's" is indexed as "hookers" and the search finds it again.
class SearchOnReferenceCitationHookersApostropheTest < ActiveSupport::TestCase
  test "search on reference citation text for hookers apostrophe" do
    params = ActiveSupport::HashWithIndifferentAccess
      .new(query_target: "reference",
           query_string: "citation-text: hookers icon pl",
           current_user: build_edit_user)
    search = Search::Base.new(params)
    assert search.executed_query.results.is_a?(ActiveRecord::Relation),
           "Results should be an ActiveRecord::Relation."
    assert_equal [ references(:hookers_icones_plantarum) ],
                 search.executed_query.results.to_a,
                 "Expected only Hooker's Icones Plantarum."
  end
end
