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

# Single Search model test.
class SearchParsedRequest20Test < ActiveSupport::TestCase
  test "search parse query 20" do
    query_string = "limit:20"
    params = ActiveSupport::HashWithIndifferentAccess.new
    params[:query_target] = "name"
    params[:canonical_query_target] = "names"
    params[:query_string] = query_string
    params[:include_common_and_cultivar_session] = true
    parsed_request = Search::ParsedRequest.new(params)
    assert parsed_request.list, "This should be parsed as a list query."
    assert !parsed_request.count, "This should not be parsed as a count query."
    assert_match(/\Aname\z/,
                 parsed_request.target_table,
                 "This should be parsed as a query on the name table.")
    assert_equal 20,
                 parsed_request.limit,
                 "This should be parsed as a query with a limit of 20."
    assert parsed_request.include_common_and_cultivar_session,
           "Parser should notice session switch to incl common and cultivars."
    assert parsed_request.where_arguments.blank?,
           "Should be parsed as a query with no where arguments."
  end
end
