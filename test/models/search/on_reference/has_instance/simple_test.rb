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

# Search model tests for the has-instance: / has-no-instance: reference
# search directives (and their has-instances: / has-no-instances:
# abbreviations).
#
# paper_by_brassard has a direct instance (triodia_in_brassard);
# book_by_brassard and journal_with_papers have none (see
# test/fixtures/instances.yml).
class SearchOnReferenceHasInstanceSimpleTest < ActiveSupport::TestCase
  # There are more reference fixtures than the default result limit, so
  # searches that match most of them need an explicit limit to be
  # deterministic.
  ALL = "limit: 500"

  def search_ids(query_string)
    params = ActiveSupport::HashWithIndifferentAccess.new(
      query_target: "reference",
      query_string: query_string,
      current_user: build_edit_user
    )
    search = Search::Base.new(params)
    search.executed_query.results.collect(&:id)
  end

  test "has-instance: includes a reference with a direct instance" do
    assert_includes search_ids("has-instance: #{ALL}"),
                    references(:paper_by_brassard).id,
                    "Expected the reference with an instance in the results"
  end

  test "has-instance: excludes a reference with no direct instance" do
    ids = search_ids("has-instance: #{ALL}")
    refute_includes ids, references(:book_by_brassard).id,
                    "Expected a reference with no instance to be excluded"
    refute_includes ids, references(:journal_with_papers).id,
                    "Expected a reference with no instance to be excluded"
  end

  test "has-no-instance: includes a reference with no direct instance" do
    ids = search_ids("has-no-instance: #{ALL}")
    assert_includes ids, references(:book_by_brassard).id,
                    "Expected a reference with no instance in the results"
    assert_includes ids, references(:journal_with_papers).id,
                    "Expected a reference with no instance in the results"
  end

  test "has-no-instance: excludes a reference with a direct instance" do
    refute_includes search_ids("has-no-instance: #{ALL}"),
                    references(:paper_by_brassard).id,
                    "Expected the reference with an instance to be excluded"
  end

  test "the two directives return disjoint result sets" do
    with_instance = search_ids("has-instance: #{ALL}")
    without_instance = search_ids("has-no-instance: #{ALL}")
    assert_empty with_instance & without_instance,
                 "A reference cannot both have and not have an instance"
  end

  test "has-instances: abbreviation behaves the same as has-instance:" do
    assert_equal search_ids("has-instance: #{ALL}"),
                 search_ids("has-instances: #{ALL}")
  end

  test "has-no-instances: abbreviation behaves the same as has-no-instance:" do
    assert_equal search_ids("has-no-instance: #{ALL}"),
                 search_ids("has-no-instances: #{ALL}")
  end

  test "has-instance: combines with a leading citation search term" do
    ids = search_ids("brassard has-instance: #{ALL}")
    assert_includes ids, references(:paper_by_brassard).id,
                    "Expected the citation term and has-instance: to combine"
    refute_includes ids, references(:book_by_brassard).id,
                    "Expected a brassard reference with no instance to be excluded"
  end
end
