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

# NSL-6004
class SearchControllerInvalidRegexTest < ActionDispatch::IntegrationTest
  def search_as_fred(params)
    sign_in_as_fake_user(username: "fred", full_name: "Fred Jones", groups: []) do
      get search_path, params: params
    end
  end

  test "an invalid regex argument shows an error naming the directive" do
    search_as_fred(query_target: "Instances", query_string: "tree-dist-matches: *wa")

    assert_response :success
    assert_select "#search-results-summary", /tree-dist-matches: takes a regular expression/
    assert_select "#search-results-summary", /quantifier operand invalid/
  end

  test "a bare asterisk regex argument shows the has-any-value note" do
    search_as_fred(query_target: "Instances", query_string: "apc-dist-note-matches: *")

    assert_response :success
    assert_select "#search-results-summary", /apc-dist-note-matches: takes a regular expression/
  end

  test "an invalid regex error from Postgres shows a regex-specific message" do
    # Raising inside the rescue sets the PG error as the cause, as Rails does.
    raise_invalid_regex = lambda do
      raise PG::InvalidRegularExpression, "invalid regular expression"
    rescue PG::InvalidRegularExpression
      raise ActiveRecord::StatementInvalid, "PG::InvalidRegularExpression"
    end
    SearchController.stub_any_instance(:run_local_search, raise_invalid_regex) do
      search_as_fred(query_target: "Names", query_string: "angophora")
    end

    assert_response :success
    assert_match(/not a valid regular\s+expression/, response.body)
  end
end
