
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

# Single Search model test.
class SearchLoaderNameAndPrintSimpleWithAnyBatchTest < ActiveSupport::TestCase
  test "search loader name with any-batch print" do
    params = ActiveSupport::HashWithIndifferentAccess.new(query_target:
                                                          "loader_names",
                                                          query_string:
                                                          "* any-batch: print:",
                                                          current_user:
                                                          build_edit_user)
    search = Search::Base.new(params)
    assert search.executed_query.results.is_a?(Array),
      "Results should be an Array."
    assert_equal 26,
                 search.executed_query.results.size,
                 "Exactly 26 results expected (9 original + 2 extra from " \
                 "accepted_one/accepted_two's formatted_text_above/" \
                 "formatted_text_below, each of which " \
                 "RewriteResultsShowingExtras expands into its own row " \
                 "(see test/fixtures/loader_names.yml and the " \
                 "formatted-note: directive tests) + 11 from " \
                 "Loader::Name::MakeOneInstance guard-ordering tests - " \
                 "none of the 11 set comment/distribution or " \
                 "formatted_text_above/below, so " \
                 "RewriteResultsShowingExtras adds exactly 1 entry per " \
                 "record with no expansion, even for the 3 that are " \
                 "record_type accepted - + 4 from the " \
                 "name-match-no-primary: directive tests, which also " \
                 "don't set comment/distribution or formatted_text_above/" \
                 "below)."
  end
end
