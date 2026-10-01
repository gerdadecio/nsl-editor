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

# Name status options tests.
class OptionsForOtherCategoryTest < ActiveSupport::TestCase
  test "should include  [n/a]" do
    assert NameStatus
      .options_for_category(name_categories(:other))
      .collect(&:first)
      .include?("[n/a]"),
           'Other category name status options should include "[n/a]"'
  end

  test "should have only one entry" do
    assert_equal 1,
                 NameStatus.options_for_category(name_categories(:other)).size,
                 "Wrong number of name status options for other category"
  end
end
