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

# NSL-6004: regex directives in each search engine.
class SearchRegexArgumentDirectivesTest < ActiveSupport::TestCase
  def search(query_target, query_string)
    Search::Base.new(
      ActiveSupport::HashWithIndifferentAccess.new(
        query_target: query_target,
        query_string: query_string,
        current_user: build_edit_user,
      ),
    )
  end

  # The search from the production logs that prompted NSL-6004.
  test "instance tree-dist-matches: with a bare asterisk runs, with a note" do
    result = search("instance", "name: Grevillea tree-dist-matches:*")
    assert result.executed_query.results.is_a?(ActiveRecord::Relation)
    assert_match(/tree-dist-matches: takes a regular expression/, result.parsed_request.note_to_user)
  end

  test "instance apc-dist-note-matches: with a bare asterisk finds notes" do
    result = search("instance", "apc-dist-note-matches: *")
    assert_not result.executed_query.results.empty?, "Results expected."
    assert_match(/apc-dist-note-matches: takes a regular expression/, result.parsed_request.note_to_user)
  end

  test "instance note-key note-matches: with a bare asterisk runs, with a note" do
    result = search("instance", "type-note-matches: *")
    assert result.executed_query.results.is_a?(ActiveRecord::Relation)
    assert_match(/type-note-matches: takes a regular expression/, result.parsed_request.note_to_user)
  end

  test "instance tree-dist-matches: with an invalid pattern explains the problem" do
    error = assert_raises(RuntimeError) { search("instance", "tree-dist-matches: *wa") }
    assert_match(/tree-dist-matches: takes a regular expression/, error.message)
  end

  test "the note appears once even though count and list both build the query" do
    result = search("instance", "apc-dist-note-matches: *")
    assert_equal 1, result.parsed_request.note_to_user.scan("takes a regular expression").size
  end

  test "name regex-name: keeps asterisks so .* works" do
    result = search("name", "regex-name: .*")
    assert_not result.executed_query.results.empty?, "Results expected."
    assert_equal "", result.parsed_request.note_to_user
  end

  test "name regex-name: with an invalid pattern explains the problem" do
    error = assert_raises(RuntimeError) { search("name", "regex-name: +a") }
    assert_match(/regex-name: takes a regular expression/, error.message)
  end

  test "reference pub-date-matches: keeps asterisks so .* works" do
    result = search("reference", "pub-date-matches: .*")
    assert_not result.executed_query.results.empty?, "Results expected."
  end

  test "reference iso-pub-date-matches: with a bare asterisk runs, with a note" do
    result = search("reference", "iso-pub-date-matches: *")
    assert_not result.executed_query.results.empty?, "Results expected."
    assert_match(/iso-pub-date-matches: takes a regular expression/, result.parsed_request.note_to_user)
  end

  test "references with instances pub-date-matches: with a bare asterisk runs, with a note" do
    result = search("references with instances", "pub-date-matches: *")
    assert_match(/pub-date-matches: takes a regular expression/, result.parsed_request.note_to_user)
  end
end
