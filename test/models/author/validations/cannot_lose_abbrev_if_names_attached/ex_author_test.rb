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
class AuthorCannotLoseAbbrevIfNamesExAuthorTest < ActiveSupport::TestCase
  test "author cannot lose abbrev if names attached to ex author" do
    author = authors(:has_ex_authored_one_name_that_is_all)
    assert author.valid?, "Author should start out valid"
    assert_not author.ex_names.empty?,
      "Author should have at least one ex-authored name attached"
    assert author.abbrev.present?,
      "Author should start out with an abbreviation."
    author.abbrev = ""
    assert_not author.valid?,
      "Author with ex-authored names should not be valid without an
               abbrev"
  end
end
