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
class ReaderSearchContNamesCommentsButNoInstListTst < ActionDispatch::IntegrationTest
  test "reader can search for a name with comments but no instances" do
    skip "Is name search for comments-but-no-instances
         required?  If so, here is the test."
    # get(:search,
    #     {query_target: 'name', query_string: 'comments-but-no-instances:'},
    #     {username: 'fred', user_full_name: 'Fred Jones', groups: []})
    # assert_response :success
    # assert_select '#search-results-summary',
    #               /\b1 record\b/,
    #               "Should find 1 or more recs for comments-but-no-instances:"
  end
end
