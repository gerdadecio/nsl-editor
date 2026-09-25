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

# Single Reference model test.
class ChapterInvalidWithNonBookParentTest < ActiveSupport::TestCase
  setup do
    @ref = references(:chapter_without_parent)
  end

  test "chapter invalid with non book parent" do
    part1
    part2
    part3
  end

  def part1
    assert(@ref.parent.blank?, "Chapter should start test without parent")
    assert(
      @ref.valid?,
      "chapter without parent should be valid - starting condition.",
    )
    @ref.parent = references(:a_book)
    assert(@ref.valid?, "Chapter with book parent should be valid.")
    @ref.parent = references(:a_chapter)
    assert_not(@ref.valid?, "Chapter with chapter parent should be invalid.")
    @ref.parent = references(:a_database)
    assert_not(@ref.valid?, "Chapter with database parent should be invalid.")
  end

  def part2
    @ref.parent = references(:a_database_record)
    assert_not(
      @ref.valid?,
      "Chapter with database record parent should be invalid.",
    )
    @ref.parent = references(:an_herbarium_annotation)
    assert_not(
      @ref.valid?,
      "Chapter with herbarium annotation parent should be invalid.",
    )
    @ref.parent = references(:an_index)
    assert_not(@ref.valid?, "Chapter with index parent should be invalid.")
    @ref.parent = references(:a_journal)
    assert_not(@ref.valid?, "Chapter with journal parent should be invalid.")
  end

  def part3
    @ref.parent = references(:a_series)
    assert_not(@ref.valid?, "Chapter with series parent should be invalid.")
    @ref.parent = references(:a_paper)
    assert_not(@ref.valid?, "Chapter with paper parent should be invalid.")
    @ref.parent = references(:a_section)
    assert_not(@ref.valid?, "Chapter with section parent should be invalid.")
    @ref.parent = references(:an_unknown)
    assert_not(@ref.valid?, "Chapter with an unknown parent should be invalid.")
  end
end
