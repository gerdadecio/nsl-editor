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
#
# The list: directive must only consume the exact "list:" token.  An unanchored
# regex here would also swallow any other directive ending in "list:" - notably
# "family-list:" on loader name searches - silently dropping the user's filter
# while leaving its value behind to be matched against the default field.
class SearchParsedRequestListDirectiveKeepsSimilarTokenTest < ActiveSupport::TestCase
  test "list directive does not consume a family-list directive" do
    params = ActiveSupport::HashWithIndifferentAccess.new(
      query_target: "name",
      canonical_query_target: "name",
      query_string: "list: family-list: Fabaceae"
    )
    parsed_request = Search::ParsedRequest.new(params)

    assert parsed_request.list, "This should be parsed as a list query."
    assert_not parsed_request.count,
               "This should not be parsed as a count query."
    assert_includes parsed_request.where_arguments,
                    "family-list:",
                    "The family-list: directive should survive parsing of the \
list: directive."
    assert_includes parsed_request.where_arguments,
                    "Fabaceae",
                    "The family-list: argument should survive parsing."
    assert_not_includes parsed_request.where_arguments.split(/ /),
                        "list:",
                        "The list: directive itself should be consumed."
  end
end
