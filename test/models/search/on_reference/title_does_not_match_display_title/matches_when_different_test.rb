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

# Single Search model test for Reference target.
#
# title-does-not-match-display-title: takes no argument - Reference#title
# and #display_title are both NOT NULL, and Reference#set_defaults copies
# title into display_title whenever display_title is blank, so the two
# only ever diverge when display_title has been explicitly overridden, or
# title was edited afterwards without updating display_title.
class SearchOnReferenceTitleDoesNotMatchDisplayTitleMatchesWhenDifferentTest < ActiveSupport::TestCase
  test "matches a reference whose title and display_title differ" do
    reference = references(:simple)
    assert_not_equal reference.title, reference.display_title

    params =  ActiveSupport::HashWithIndifferentAccess
              .new(query_target: "reference",
                   query_string: "title-does-not-match-display-title:",
                   current_user: build_edit_user)
    search = Search::Base.new(params)
    assert search.executed_query.results.is_a?(ActiveRecord::Relation),
           "Results should be an ActiveRecord::Relation."
    assert_includes search.executed_query.results.map(&:id), reference.id
  end
end
