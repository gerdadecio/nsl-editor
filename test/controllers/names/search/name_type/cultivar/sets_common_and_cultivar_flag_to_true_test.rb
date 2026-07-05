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

# Single controller test.
class NameSearch4NameTypeCultSetsCommCultFlagTrueT < ActionController::TestCase
  tests SearchController

  test "editor search for name type cultivar should set cultivar flag true" do
    skip # Expect this to be no longer needed under revised search.
    cultivar = names(:a_cultivar)
    # Set the common-and-cultivar flag to false.
    get(:search,
        params: { "query" => "nt:cultivar",
                  "query_limit" => "100" },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: ["edit"] })
    assert_response :success
    # assert_select "input.checkbox[type=checkbox]
    # [id=query_common_and_cultivar][value=t]",
    # true,
    # "The query-common-and-cultivar checkbox should be true"
    assert_select "tr[id=search-result-#{cultivar.id}]",
                  true,
                  "Should find one cultivar at least"
  end
end
