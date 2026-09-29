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
# Single Name model test.
class ScientificNameCannotHaveBaseAuthorWithoutAuthor < ActiveSupport::TestCase
  require "test_helper"

  test "scientific name cannot have base author without author" do
    name = names(:scientific_name_without_author)
    assert name.valid?, "scientific name without author should be valid"
    assert_nil name.author_id, "should be no author id"
    name.base_author = authors(:bentham)
    assert_not_nil name.base_author_id,
                   "name base author id should have a value"
    assert_not name.valid?,
               "name should not be valid with a base-author and no author"
  end
end
