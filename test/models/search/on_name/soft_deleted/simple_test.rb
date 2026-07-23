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

class SearchOnNameSoftDeletedSimpleTest < ActiveSupport::TestCase
  def search_ids(query_string)
    params = ActiveSupport::HashWithIndifferentAccess.new(
      query_target: "name",
      query_string: query_string,
      current_user: build_edit_user
    )
    search = Search::Base.new(params)
    confirm_results_class(search.executed_query.results)
    search.executed_query.results.collect(&:id)
  end

  test "is-soft-deleted: includes a soft deleted name" do
    assert_includes search_ids("is-soft-deleted:"),
                    names(:a_soft_deleted_name).id,
                    "Expected the soft deleted name in the results"
  end

  test "is-soft-deleted: excludes a name that is not soft deleted" do
    refute_includes search_ids("is-soft-deleted:"),
                    names(:the_regnum).id,
                    "Expected a live name to be excluded from the results"
  end

  test "is-not-soft-deleted: includes a name that is not soft deleted" do
    assert_includes search_ids("is-not-soft-deleted:"),
                    names(:the_regnum).id,
                    "Expected a live name in the results"
  end

  test "is-not-soft-deleted: excludes a soft deleted name" do
    refute_includes search_ids("is-not-soft-deleted:"),
                    names(:a_soft_deleted_name).id,
                    "Expected the soft deleted name to be excluded"
  end

  test "the two directives return disjoint result sets" do
    deleted_ids = search_ids("is-soft-deleted:")
    live_ids = search_ids("is-not-soft-deleted:")
    assert_empty deleted_ids & live_ids,
                 "A name should never be both soft deleted and not soft deleted"
  end
end
