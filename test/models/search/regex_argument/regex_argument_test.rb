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

class SearchRegexArgumentTest < ActiveSupport::TestCase
  test "a bare asterisk becomes any value, with a note" do
    arg = Search::RegexArgument.new("tree-dist-matches:", "*")
    assert_equal ".", arg.value
    assert_match(/tree-dist-matches: takes a regular expression/, arg.note)
  end

  test "a bare asterisk with surrounding spaces becomes any value" do
    assert_equal ".", Search::RegexArgument.new("tree-dist-matches:", " * ").value
  end

  test "a valid pattern is left alone, asterisks included" do
    arg = Search::RegexArgument.new("regex-name:", "grev.*robusta")
    assert_equal "grev.*robusta", arg.value
    assert_nil arg.note
  end

  test "a blank value is left alone and not checked" do
    arg = Search::RegexArgument.new("tree-dist-matches:", "")
    assert_equal "", arg.value
    assert_nil arg.note
  end

  test "a bare percent stays a literal percent" do
    assert_equal "%", Search::RegexArgument.new("tree-dist-matches:", "%").value
  end

  test "an invalid pattern raises an error naming the directive, the value and the reason" do
    error = assert_raises(RuntimeError) do
      Search::RegexArgument.new("tree-dist-matches:", "*wa")
    end
    assert_match(/tree-dist-matches: takes a regular expression/, error.message)
    assert_match(/"\*wa" is not a valid one/, error.message)
    assert_match(/quantifier operand invalid/, error.message)
    assert_match(/Use "\.\*" to match any characters/, error.message)
  end

  test "an invalid pattern does not abort the enclosing transaction" do
    assert_raises(RuntimeError) { Search::RegexArgument.new("regex-name:", "(") }
    assert_equal 1, ActiveRecord::Base.connection.select_value("select 1")
  end
end
