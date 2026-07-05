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

# Single Search model test for Name target filtered by name tag.
class SearchOneNameTagSimpleTest < ActiveSupport::TestCase
  test "search on name tag" do
    params =  ActiveSupport::HashWithIndifferentAccess
              .new(query_target: "name",
                   query_string: "tag: acra",
                   include_common_and_cultivar_session: true,
                   current_user: build_edit_user)
    search = Search::Base.new(params)
    assert !search.executed_query.results.empty?, "Results expected."
  end

  test "search on name tag is case insensitive" do
    params =  ActiveSupport::HashWithIndifferentAccess
              .new(query_target: "name",
                   query_string: "tag: ACRA",
                   include_common_and_cultivar_session: true,
                   current_user: build_edit_user)
    search = Search::Base.new(params)
    assert !search.executed_query.results.empty?, "Results expected."
  end

  test "search on name tag with no match returns nothing" do
    params =  ActiveSupport::HashWithIndifferentAccess
              .new(query_target: "name",
                   query_string: "tag: no-such-tag",
                   include_common_and_cultivar_session: true,
                   current_user: build_edit_user)
    search = Search::Base.new(params)
    assert search.executed_query.results.empty?, "No results expected."
  end

  test "has-tags finds tagged names" do
    params =  ActiveSupport::HashWithIndifferentAccess
              .new(query_target: "name",
                   query_string: "has-tags:",
                   include_common_and_cultivar_session: true,
                   current_user: build_edit_user)
    search = Search::Base.new(params)
    assert !search.executed_query.results.empty?, "Results expected."
  end

  test "has-no-tags finds untagged names" do
    params =  ActiveSupport::HashWithIndifferentAccess
              .new(query_target: "name",
                   query_string: "has-no-tags:",
                   include_common_and_cultivar_session: true,
                   current_user: build_edit_user)
    search = Search::Base.new(params)
    assert !search.executed_query.results.empty?, "Results expected."
  end

  test "empty tag directive finds untagged names" do
    params =  ActiveSupport::HashWithIndifferentAccess
              .new(query_target: "name",
                   query_string: "tag:",
                   include_common_and_cultivar_session: true,
                   current_user: build_edit_user)
    search = Search::Base.new(params)
    assert !search.executed_query.results.empty?, "Results expected."
  end
end
