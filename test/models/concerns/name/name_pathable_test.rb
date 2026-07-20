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

# Name::NamePathable#make_name_path / #build_name_path build a name's
# slash-separated ancestry path from its parent's name_path plus its own
# name_element, with no leading slash when there is no parent.
class Name::NamePathableTest < ActiveSupport::TestCase
  test "a root name (no parent) has a path with no leading slash" do
    name = names(:the_regnum)
    assert_nil name.parent, "fixture should have no parent"
    assert_equal "Plantae", name.make_name_path
  end

  test "a name with a parent joins the parent's name_path and its own name_element with a slash" do
    name = names(:a_division)
    assert_equal names(:the_regnum), name.parent, "fixture should have the_regnum as parent"
    assert_equal "Plantae/Magnoliophyta", name.make_name_path
  end

  test "whitespace around name_element is stripped when building the path" do
    name = Name.new(name_element: "  Hibiscus  ", parent: names(:the_regnum))
    assert_equal "Plantae/Hibiscus", name.make_name_path
  end

  test "a blank parent name_path does not add a leading slash" do
    name = Name.new(name_element: "Hibiscus", parent: Name.new(name_path: ""))
    assert_equal "Hibiscus", name.make_name_path
  end

  test "no parent and no name_element returns an empty string" do
    name = Name.new
    assert_equal "", name.make_name_path
  end

  test "build_name_path sets name_path to the result of make_name_path" do
    name = Name.new(name_element: "Malvaceae")
    name.build_name_path
    assert_equal "Malvaceae", name.name_path
  end
end
