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

# Search::Loader::Name::FieldRule's "misapp-matched-without-cross-ref:"
# directive (app/models/search/loader/name/field_rule.rb) finds loader
# names that:
#   - are a misapplied record (record_type = 'misapplied'), and
#   - have a recorded loader_name_match whose relationship_instance_id is
#     still null, i.e. no cross-reference instance has been identified for
#     it yet.
#
# It takes no argument.
class SearchLoaderNameDirectivesMisappMatchedWithoutCrossRefTest < ActiveSupport::TestCase
  setup do
    params = ActiveSupport::HashWithIndifferentAccess.new(
      query_target: "loader_names",
      query_string: "misapp-matched-without-cross-ref: any-batch:",
      current_user: build_edit_user
    )
    search = Search::Base.new(params)
    @ids = search.executed_query.results.map(&:id)
  end

  test "includes a misapplied name with a match that has no cross-ref" do
    assert_includes @ids, loader_names(:misapp_matched_without_cross_ref).id
  end

  test "excludes a misapplied name whose match already has a cross-ref" do
    assert_not_includes @ids, loader_names(:misapp_matched_with_cross_ref).id
  end

  test "excludes a misapplied name with no recorded match at all" do
    assert_not_includes @ids, loader_names(:misapp_no_parent).id
  end

  test "excludes a non-misapplied name with an otherwise-matching unresolved match" do
    assert_not_includes @ids, loader_names(:synonym_guards_pass).id
  end

  # Loader::Name::Match's loader_name_id uniqueness validation is skipped
  # for misapplied names, so a misapplied name can have more than one
  # match row (see test/fixtures/loader_name_matches.yml). Having any
  # unresolved match is enough to be included, even alongside a resolved
  # one.
  test "includes a misapplied name with one resolved and one unresolved match" do
    assert_includes @ids, loader_names(:misapp_multiple_matches_one_without_cross_ref).id
  end

  test "using the directive with no argument does not raise" do
    assert_kind_of Array, @ids
  end
end
