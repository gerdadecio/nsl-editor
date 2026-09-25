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

# Reference model typeahead search.
class RefTheadsDisplayValueCitationWithPageRangeTest < ActiveSupport::TestCase
  test "ref typeahead display value citation with page range" do
    ref = references(:for_typeahead_display)
    assert_match(
      /\AFor Typeahead Display . \[2-3\] \[book\]\z/,
      ref.typeahead_display_value,
    )
  end
end
