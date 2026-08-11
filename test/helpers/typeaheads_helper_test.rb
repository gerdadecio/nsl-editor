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

class TypeaheadsHelperTest < ActionView::TestCase
  test "wraps a matching substring in strong tags" do
    result = highlight_typeahead_match("Angiospermae | legitimate", "ang")

    assert_equal "<strong>Ang</strong>iospermae | legitimate", result
  end

  test "is case insensitive" do
    result = highlight_typeahead_match("Angiospermae", "ANG")

    assert_equal "<strong>Ang</strong>iospermae", result
  end

  test "wraps every occurrence of the term" do
    result = highlight_typeahead_match("repeat repeat", "repeat")

    assert_equal "<strong>repeat</strong> <strong>repeat</strong>", result
  end

  test "returns the text unchanged (but escaped) when the term is blank" do
    assert_equal "Angiospermae", highlight_typeahead_match("Angiospermae", "")
    assert_equal "Angiospermae", highlight_typeahead_match("Angiospermae", nil)
  end

  test "returns the text unchanged (but escaped) when there is no match" do
    result = highlight_typeahead_match("No match here", "xyz")

    assert_equal "No match here", result
  end

  test "escapes HTML in the text so a full_name can't inject markup" do
    result = highlight_typeahead_match("A & B <script>", "&")

    assert_equal "A <strong>&amp;</strong> B &lt;script&gt;", result
  end

  test "escapes a special-regex-character term instead of raising" do
    result = highlight_typeahead_match("A (B) C", "(B)")

    assert_equal "A <strong>(B)</strong> C", result
  end

  test "the result is html_safe so it renders unescaped in a view" do
    result = highlight_typeahead_match("Angiospermae", "ang")

    assert result.html_safe?
  end
end
