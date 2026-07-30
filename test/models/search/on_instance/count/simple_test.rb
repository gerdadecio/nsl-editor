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

# Regression test: an instance search using the "count:" directive would
# raise NameError: uninitialized constant Search::OnInstance::CountQuery.
# That class was accidentally dropped alongside Search::OnName::CountQuery
# while merging this repo's history with an older one - see
# Search::OnInstance::Base#run_count_query, which still expects it.
class SearchOnInstanceCountSimpleTest < ActiveSupport::TestCase
  test "search on instance with count directive" do
    params = ActiveSupport::HashWithIndifferentAccess.new(
      query_target: "instance",
      query_string: "count angophora",
      current_user: build_edit_user
    )
    search = Search::Base.new(params)
    assert search.executed_query.count.is_a?(Integer),
           "Count should be a whole number"
    assert search.executed_query.count.positive?,
           "Expected at least one matching instance"
    assert_equal [], search.executed_query.results,
                 "A count query should not also return a list of results"
  end
end
