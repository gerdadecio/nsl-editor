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

# Search::Loader::Name::FieldRule's "formatted-note:" directive
# (app/models/search/loader/name/field_rule.rb) matches a term,
# case-insensitively with wildcards at both ends, against
# formatted_text_above OR formatted_text_below. A bare "*" argument matches
# any record with either field non-null, so it doubles as an existence
# check across both fields.
#
# accepted_one has formatted_text_above set, accepted_two has
# formatted_text_below set, accepted_three has neither (see
# test/fixtures/loader_names.yml).
class SearchLoaderNameDirectivesFormattedNoteTest < ActiveSupport::TestCase
  def ids_for(query_string)
    params = ActiveSupport::HashWithIndifferentAccess.new(
      query_target: "loader_names",
      query_string: query_string,
      current_user: build_edit_user
    )
    Search::Base.new(params).executed_query.results.map(&:id)
  end

  test "matches a term found only in formatted_text_above" do
    ids = ids_for("formatted-note: stray any-batch:")
    assert_includes ids, loader_names(:accepted_one).id
    assert_not_includes ids, loader_names(:accepted_two).id
    assert_not_includes ids, loader_names(:accepted_three).id
  end

  test "matches a term found only in formatted_text_below" do
    ids = ids_for("formatted-note: appendix any-batch:")
    assert_includes ids, loader_names(:accepted_two).id
    assert_not_includes ids, loader_names(:accepted_one).id
    assert_not_includes ids, loader_names(:accepted_three).id
  end

  test "a bare asterisk finds records with either field populated" do
    ids = ids_for("formatted-note:* any-batch:")
    assert_includes ids, loader_names(:accepted_one).id
    assert_includes ids, loader_names(:accepted_two).id
    assert_not_includes ids, loader_names(:accepted_three).id
  end
end
