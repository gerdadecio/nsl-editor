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

# Test search on instance using the is-relationship: directive.
# Fixtures with relationship instance types (e.g.
# metrosideros_costata_is_basionym_of_angophora_costata, which is a
# basionym instance, and inst_species_or_below_to_be_synonym, which is a
# nomenclatural_synonym instance) should be returned.
class SearchOnInstanceIsRelationshipTest < ActiveSupport::TestCase
  test "is-relationship: returns instances with a relationship instance type" do
    search = Search::Base.new(
      ActiveSupport::HashWithIndifferentAccess.new(
        query_target: "instance",
        query_string: "is-relationship:",
        current_user: build_edit_user
      )
    )
    assert !search.executed_query.results.empty?,
           "Expected results for is-relationship: — fixtures include basionym and nomenclatural_synonym instances"
  end
end
