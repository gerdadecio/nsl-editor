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

# Reference tests.  Most now split into single-test files.
class ReferenceTest < ActiveSupport::TestCase
  def try_citation(ref, expected, msg = "unexplained error", debug = false)
    ref.save!
    debug(ref) if debug
    assert(
      ref.citation.match(Regexp.new(Regexp.escape(expected))),
      "#{msg}; \nexpected: #{expected}; \ngot:
           \"#{ref.citation}\"",
    )
  end

  def debug(ref)
    part_1(ref)
    part_2(ref)
  end

  def part_1(ref)
    puts "ref.title: #{ref.title}"
    puts "ref.author.name: #{ref.author.name}" if ref.author
    puts ref.parent ? "ref has parent" : "ref has no parent"
  end

  def part_2(ref)
    puts "ref.parent.author.name: #{ref.parent.author.name}" if ref.parent
    puts "ref.parent_has_same_author?: #{ref.parent_has_same_author?}"
    puts "ref.citation: #{ref.citation}"
  end

  test "test for has children" do
    assert references(:journal_with_children).children?,
      "Children not detected."
  end

  test "test for has no children" do
    assert_not references(:ref_without_children).children?,
      "Children found where none exist."
  end
end
