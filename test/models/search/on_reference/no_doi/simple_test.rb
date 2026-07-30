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

# Search::Reference::FieldRule's "no-doi:" directive
# (app/models/search/reference/field_rule.rb) finds references with no DOI
# recorded. It takes no argument - there isn't one to give - so using it
# alone, with nothing after the colon, must not raise.
class SearchOnReferenceNoDoiSimpleTest < ActiveSupport::TestCase
  setup do
    params = ActiveSupport::HashWithIndifferentAccess.new(
      query_target: "reference",
      query_string: "no-doi:",
      current_user: build_edit_user
    )
    search = Search::Base.new(params)
    @results = search.executed_query.results
    @ids = @results.map(&:id)
  end

  test "using the directive with no argument does not raise" do
    assert_kind_of ActiveRecord::Relation, @results
  end

  test "includes a reference with no doi recorded" do
    assert_includes @ids, references(:ref_type_is_book).id
  end

  test "excludes a reference that has a doi recorded" do
    assert_not_includes @ids,
                        references(:stanley_and_ross_1986_flora_of_se_qld).id
  end
end
