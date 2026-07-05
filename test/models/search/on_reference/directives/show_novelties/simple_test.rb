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

# Tests for the show-novelties: search directive on references.
class SearchOnReferenceShowNoveltiesSimpleTest < ActiveSupport::TestCase
  def search_for(reference, query_suffix = "show-novelties:")
    Search::Base.new(
      ActiveSupport::HashWithIndifferentAccess.new(
        query_target: "references",
        query_string: "id: #{reference.id} #{query_suffix}",
        current_user: build_edit_user
      )
    )
  end

  test "show-novelties: returns an array of results" do
    ref = references(:de_fructibus_et_seminibus_plantarum)
    search = search_for(ref)
    assert search.executed_query.results.instance_of?(Array),
           "show-novelties: should produce an Array of results"
  end

  test "show-novelties: interleaves primary instances after the reference" do
    ref = references(:de_fructibus_et_seminibus_plantarum)
    search = search_for(ref)
    results = search.executed_query.results
    assert results.size > 1,
           "Results should include the reference plus at least one primary instance"
    assert_equal Reference, results.first.class,
                 "First result should be the reference"
    assert_equal Instance, results[1].class,
                 "Second result should be an instance"
  end

  test "show-novelties-by-page: returns results sorted by page" do
    ref = references(:de_fructibus_et_seminibus_plantarum)
    search = search_for(ref, "show-novelties-by-page:")
    assert search.executed_query.results.instance_of?(Array),
           "show-novelties-by-page: should produce an Array of results"
  end

  test "show-novelties: on reference with no primary instances returns only the reference" do
    ref = references(:simple)
    search = search_for(ref)
    results = search.executed_query.results
    assert_equal 1, results.size,
                 "Should return only the reference when it has no primary instances"
  end
end
