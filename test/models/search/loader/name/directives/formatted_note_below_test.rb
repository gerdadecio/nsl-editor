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

# Search::Loader::Name::FieldRule's "formatted-note-below:" directive
# (app/models/search/loader/name/field_rule.rb) matches against
# formatted_text_below, case-insensitively, with wildcards added at both
# ends. A bare "*" argument matches any non-null value, so it doubles as an
# existence check.
#
# accepted_two has formatted_text_below set (mixed case); accepted_one and
# accepted_three do not (see test/fixtures/loader_names.yml).
class SearchLoaderNameDirectivesFormattedNoteBelowTest < ActiveSupport::TestCase
  def ids_for(query_string)
    params = ActiveSupport::HashWithIndifferentAccess.new(
      query_target: "loader_names",
      query_string: query_string,
      current_user: build_edit_user
    )
    Search::Base.new(params).executed_query.results.map(&:id)
  end

  test "matches a lower-case search term against mixed-case stored text" do
    ids = ids_for("formatted-note-below: appendix any-batch:")
    assert_includes ids, loader_names(:accepted_two).id
  end

  test "does not match a record with no formatted_text_below" do
    ids = ids_for("formatted-note-below: appendix any-batch:")
    assert_not_includes ids, loader_names(:accepted_one).id
    assert_not_includes ids, loader_names(:accepted_three).id
  end

  test "a non-matching term excludes the record that has formatted_text_below" do
    ids = ids_for("formatted-note-below: no-such-text-anywhere any-batch:")
    assert_not_includes ids, loader_names(:accepted_two).id
  end

  test "a bare asterisk acts as an existence check" do
    ids = ids_for("formatted-note-below:* any-batch:")
    assert_includes ids, loader_names(:accepted_two).id
    assert_not_includes ids, loader_names(:accepted_one).id
    assert_not_includes ids, loader_names(:accepted_three).id
  end
end
