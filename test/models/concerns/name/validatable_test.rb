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

# Name::Validatable#name_path_no_slash_unless_parent rejects a leading slash
# on name_path when the name has no parent (a root name's path should just
# be its own name_element), but allows a leading slash when there is a
# parent.
class Name::ValidatableTest < ActiveSupport::TestCase
  test "a root name's name_path may not have a leading slash" do
    name = names(:the_regnum)
    assert_nil name.parent, "fixture should have no parent"
    assert name.valid?, "Name should be valid. Errs: #{name.errors.full_messages.join('; ')}"

    name.name_path = "/Plantae"

    assert_not name.valid?
    assert_includes name.errors[:name_path], "should have no leading slash because no parent"
  end

  test "a root name's name_path with no leading slash is valid" do
    name = names(:the_regnum)
    name.name_path = "Plantae"

    assert name.valid?, "Name should be valid. Errs: #{name.errors.full_messages.join('; ')}"
  end

  test "a blank name_path on a root name does not raise, though it is invalid for a different reason" do
    name = names(:the_regnum)
    name.name_path = ""

    assert_not name.valid?
    refute_includes name.errors[:name_path], "should have no leading slash because no parent"
    assert_includes name.errors[:name_path], "can't be blank"
  end

  test "a nil name_path on a root name does not raise" do
    name = names(:the_regnum)
    name.name_path = nil

    assert_nothing_raised { name.valid? }
  end

  test "a name with a parent may have a leading slash in name_path" do
    name = names(:a_division)
    assert name.parent.present?, "fixture should have a parent"
    name.name_path = "/Plantae/Magnoliophyta"

    assert name.valid?, "Name should be valid. Errs: #{name.errors.full_messages.join('; ')}"
  end
end
