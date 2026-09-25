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

# Single Name model test.
class BaseAuthorExBaseAuthorMustDifferOnUpdateTest < ActiveSupport::TestCase
  test "base author and ex base author must be different" do
    name = names(:triodia_basedowii)
    assert name.author.present?, "Existing name should have an author."
    assert name.valid?,
      "Existing name should be valid.
           Errors: #{name.errors.full_messages.join("; ")}"
    name.base_author = authors(:joe)
    assert name.valid?,
      "Existing name should be valid with a base author.
           Errors: #{name.errors.full_messages.join("; ")}"
    name.ex_base_author = authors(:fred)
    assert name.valid?,
      "Existing name should be valid with an ex-base author.
           Errors: #{name.errors.full_messages.join("; ")}"
    name.ex_base_author = name.base_author
    assert_not name.valid?,
      "Name should NOT be valid with matching base auth/ex-base auth."
    assert_equal name.errors.full_messages.first,
      "The ex-base author cannot be the same as the base author.",
      "Wrong error message."
  end
end
