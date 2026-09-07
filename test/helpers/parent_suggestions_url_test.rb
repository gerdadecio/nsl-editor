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

# TypeaheadsHelper#parent_suggestions_url_for - where the name form's Parent
# field fetches its suggestions from, which the field used to decide by
# rendering one of three typeahead.js set-up calls.
class ParentSuggestionsUrlTest < ActionView::TestCase
  tests TypeaheadsHelper

  test "sends a hybrid name to the hybrid parent endpoint" do
    assert_equal "/suggestions/name/hybrid_parent.html",
                 parent_suggestions_url_for(names(:hybrid_formula))
  end

  test "sends a cultivar name to the cultivar parent endpoint" do
    assert_equal "/suggestions/name/cultivar_parent.html",
                 parent_suggestions_url_for(names(:a_cultivar))
  end

  test "sends every other name to the general parent endpoint" do
    assert_equal "/names/name_parent_suggestions.html",
                 parent_suggestions_url_for(names(:a_species))
  end

  # The endpoints answer json to the fields still on typeahead.js, so the
  # html fragment has to be asked for by extension.
  test "asks for the html format by extension" do
    assert parent_suggestions_url_for(names(:a_species)).end_with?(".html")
  end
end
