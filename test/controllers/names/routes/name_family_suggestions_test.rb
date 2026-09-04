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

# Single controller test.
class NameFamilySuggestionsRouteTest < ActionController::TestCase
  tests NamesController
  test "should route to name family suggestions" do
    assert_routing "/names/name_family_suggestions",
                   controller: "names",
                   action: "name_family_suggestions"
  end

  # stimulus-autocomplete asks for the html fragment by extension rather than
  # by Accept header - see Name::Typeaheads#name_family_suggestions and
  # AuthorsController#typeahead_on_abbrev's comment for why.
  test "should route the html format to the same action" do
    assert_routing "/names/name_family_suggestions.html",
                   controller: "names",
                   action: "name_family_suggestions",
                   format: "html"
  end
end
