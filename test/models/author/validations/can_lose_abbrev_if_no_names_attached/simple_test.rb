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
class AuthorCanLoseAbbrevIfNoNamesSimpleTest < ActiveSupport::TestCase
  test "author can lose abbrev if no names attached" do
    author = authors(:joe)
    assert author.valid?, "Joe should be valid"
    assert_equal 0,
      author.names.size,
      "Joe should have no names attached"
    assert author.abbrev.present?, "Joe should start with an abbreviation."
    author.abbrev = ""
    assert author.valid?, "Joe should be valid without an abbrev"
    author.save!
  end
end
