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

# Single Search model test.
class SearchOnNameParOr2ndParIdCultivarsInclByDefTest < ActiveSupport::TestCase
  test "search on name parent or 2nd parent id cultivars included by default" do
    name = names(:a_cultivar)
    params = ActiveSupport::HashWithIndifferentAccess.new(
      query_target: "name",
      query_string: "parent-or-second-parent-id: #{name.id}",
      current_user: build_edit_user
    )
    search = Search::Base.new(params)
    confirm_results_class(search.executed_query.results)
    assert_equal 1,
                 search.executed_query.results.size,
                 "Expect cultivar by default for parent or 2nd parent id query"
  end
end
