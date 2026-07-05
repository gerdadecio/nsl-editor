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
load "test/models/search/on_name/test_helper.rb"

# Search for names that are novelties (primary instances) for a given reference.
class SearchOnNameNovelNamesForRefSimpleTest < ActiveSupport::TestCase
  # de_fructibus_et_seminibus_plantarum has one comb_nov (primary) instance:
  # gaertner_created_metrosideros_costata -> metrosideros_costata
  test "novel-names-for-ref returns names with primary instances for the reference" do
    ref = references(:de_fructibus_et_seminibus_plantarum)
    params = ActiveSupport::HashWithIndifferentAccess.new(
      query_target: "name",
      query_string: "novel-names-for-ref: #{ref.id}",
      current_user: build_edit_user
    )
    search = Search::Base.new(params)
    confirm_results_class(search.executed_query.results)
    assert !search.executed_query.results.empty?,
           "Expected at least one novel name for reference #{ref.id}"
  end

  # ref_4_genus_or_above_to_be_synonym only has nomenclatural_synonym and
  # secondary_reference instances - neither has primary_instance = true
  test "novel-names-for-ref returns no results for a reference with no primary instances" do
    ref = references(:ref_4_genus_or_above_to_be_synonym)
    params = ActiveSupport::HashWithIndifferentAccess.new(
      query_target: "name",
      query_string: "novel-names-for-ref: #{ref.id}",
      current_user: build_edit_user
    )
    search = Search::Base.new(params)
    confirm_results_class(search.executed_query.results)
    assert search.executed_query.results.empty?,
           "Expected no novel names for a reference with no primary instances"
  end
end
