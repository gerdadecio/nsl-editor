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

# Single Search model test.
# type: is one of the directives flagged allow_common_and_cultivar: true in
# config/name-searches.yml, so it would normally auto-include commons.  An
# explicit include-common-and-cultivar:false directive must still win.
class SearchOnNameNameDirectiveOverridesYamlAllowRuleTest < ActiveSupport::TestCase
  test "search on name name include-common-and-cultivar directive false overrides yaml allow rule" do
    params = ActiveSupport::HashWithIndifferentAccess.new(
      query_target: "name",
      query_string: "name: argyle apple type: common include-common-and-cultivar:false",
      current_user: build_edit_user
    )
    search = Search::Base.new(params)
    confirm_results_class(search.executed_query.results)
    assert_equal 0,
                 search.executed_query.results.size,
                 "Expected common name to be excluded because the directive overrode the yaml allow_common_and_cultivar rule"
  end
end
