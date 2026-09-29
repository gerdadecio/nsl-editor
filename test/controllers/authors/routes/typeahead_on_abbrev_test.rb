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
class AuthorsTypeaheadOnAbbrevRouteTest < ActionController::TestCase
  tests AuthorsController

  test "should route to authors typeahead on abbrev" do
    assert_routing "/authors/typeahead_on_abbrev",
                   controller: "authors",
                   action: "typeahead_on_abbrev"
  end

  # stimulus-autocomplete asks for the html fragment by extension rather than
  # by Accept header - see AuthorsController#typeahead_on_abbrev.
  test "should route the html format to the same action" do
    assert_routing "/authors/typeahead_on_abbrev.html",
                   controller: "authors",
                   action: "typeahead_on_abbrev",
                   format: "html"
  end
end
