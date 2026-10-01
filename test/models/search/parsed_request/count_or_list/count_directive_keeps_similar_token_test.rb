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
# The count: directive must only consume the exact "count:" token.  No search
# field currently ends in "count:", so this guards against a latent bug rather
# than a live one - but the parsing rule should hold regardless of which fields
# happen to exist.
class SearchParsedRequestCountDirectiveKeepsSimilarTokenTest < ActiveSupport::TestCase
  test "count directive does not consume a similar token" do
    params = ActiveSupport::HashWithIndifferentAccess.new(
      query_target: "name",
      canonical_query_target: "name",
      query_string: "count: comment-count: 3"
    )
    parsed_request = Search::ParsedRequest.new(params)

    assert parsed_request.count, "This should be parsed as a count query."
    assert_not parsed_request.list,
               "This should not be parsed as a list query."
    assert_includes parsed_request.where_arguments,
                    "comment-count:",
                    "A directive ending in count: should survive parsing of \
the count: directive."
    assert_not_includes parsed_request.where_arguments.split(/ /),
                        "count:",
                        "The count: directive itself should be consumed."
  end
end
