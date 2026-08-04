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

# Test search on instance using the is-not-relationship: directive.
# Fixtures with non-relationship instance types (e.g.
# gaertner_created_metrosideros_costata and
# britten_created_angophora_costata, which are comb_nov instances)
# should be returned.
class SearchOnInstanceIsNotRelationshipTest < ActiveSupport::TestCase
  test "is-not-relationship: returns instances with a non-relationship instance type" do
    search = Search::Base.new(
      ActiveSupport::HashWithIndifferentAccess.new(
        query_target: "instance",
        query_string: "is-not-relationship:",
        current_user: build_edit_user
      )
    )
    assert !search.executed_query.results.empty?,
           "Expected results for is-not-relationship: — fixtures include comb_nov instances"
  end
end
