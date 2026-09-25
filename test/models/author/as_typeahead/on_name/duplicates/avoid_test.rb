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

# Single author model test.
class AuthorTypeaheadsOnNameDuplicatesAvoidTest < ActiveSupport::TestCase
  test "author typeahead on name duplicates avoid" do
    duplicate = authors(:schlechter_a_duplicate)
    results = Author::AsTypeahead.on_name("schlechter")
    assert_not results.collect { |r| r[:id] }.include?(duplicate.id.to_s),
      "Duplicate author should not be in typeahead"
  end
end
