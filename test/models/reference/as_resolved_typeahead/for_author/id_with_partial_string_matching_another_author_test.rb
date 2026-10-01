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

# Reference model typeahead test.
class RefARTA4AuthorWPartStrMatchingAnotherAuthorTest < ActiveSupport::TestCase
  test "author id with partial string for another author" do
    author_1 = authors(:chaplin)
    author_2 = authors(:moe)
    result = Reference::AsResolvedTypeahead::ForAuthor.new(
      author_1.id.to_s,
      author_2.name.chop
    )
    assert_equal author_2.id,
                 result.value,
                 "Should get matching ID 4 name despite mismatched ID and \
                 partial name"
  end
end
