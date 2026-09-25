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

# Single model test.
class AuthorTest < ActiveSupport::TestCase
  test "typeahead on name should excl auth w abbrev even empty str abbrev" do
    typeahead = Author::AsTypeahead.on_name("for typeahead on name")
    assert_instance_of(Array, typeahead, "Typeahead on name shld return array")
    typeahead_ids = typeahead.collect { |val| val[:id].to_i }
    assert_includes(
      typeahead_ids,
      authors(:for_typeahead_on_name_null_abbrev).id,
      "Author should be in typeahead list",
    )
    assert_includes(
      typeahead_ids,
      authors(:for_typeahead_on_name_has_abbrev).id,
      "Author should be in typeahead list",
    )
    assert_includes(
      typeahead_ids,
      authors(:for_typeahead_on_name_empty_string_abbrev).id,
      "Author with empty string abbrev shld be in typeahead",
    )
  end
end
