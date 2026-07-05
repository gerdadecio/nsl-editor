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

# Single search controller test.
class SearchRefsOutputFormatWithInstancesTest < ActionController::TestCase
  tests SearchController

  test "output format of reference search with instances" do
    ref = references(:bucket_reference_for_default_instances)
    get(:search,
        params: { query_target: "reference",
                  query_string: "citation: #{ref.citation} show-instances:" },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: [] })
    assert_response :success
    assert_select "a.show-details-link.indent-level-1",
                  /Metrosideros costata Gaertn./,
                  "Need Metrosideros costata Gaertn. for the orth. var. test"
    assert_select "a.show-details-link.indent-level-1" do
      assert_select "span.non-legit-name-status",
                    /orth. var./,
                    "Orth var. name formatted incorrectly"
    end
    assert_select "#search-results-summary",
                  /37 records\b/,
                  "Should find 37 records"
  end
end
