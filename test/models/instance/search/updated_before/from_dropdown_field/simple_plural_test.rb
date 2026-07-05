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
load "models/search/users.rb"

# Single instance model test.
class InstSrchUpdatedBeforeDropdownSimplePluralTest < ActiveSupport::TestCase
  # New search for "42993" on instance up to 100 with field: upd-b
  test "instance search on updated before from dropdown field simple plural" do
    skip # this was an upd-b search in the old version of search -
    # no translation yet
    # search = Search::Base.new({query_string:"more-than-2 instances-only",
    #                            query_string:'review'})
    # assert search.executed_query.results.is_a?(ActiveRecord::Relation),
    #   "Results should be an ActiveRecord::Relation."
    # assert search.results.size > 0, "At least 1 record expected."
    # assert_match /Search for instances updated more than 2 days ago./,
    #              search.info.join
  end
end
