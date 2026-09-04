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

# A suggestion request with no term at all reaches these class methods with
# a nil term - the endpoints are plain GETs, and the term is only ever
# present because the field puts it there.
class ParentSuggestionsWithNoTermTest < ActiveSupport::TestCase
  test "hybrid parent suggestions for a nil term" do
    assert_empty Name::AsTypeahead.hybrid_parent_suggestions(nil, -1)
  end

  test "hybrid parent suggestions for a blank term" do
    assert_empty Name::AsTypeahead.hybrid_parent_suggestions("  ", -1)
  end

  test "cultivar parent suggestions for a nil term" do
    assert_empty Name::AsTypeahead.cultivar_parent_suggestions(nil, -1)
  end

  test "cultivar parent suggestions for a blank term" do
    assert_empty Name::AsTypeahead.cultivar_parent_suggestions("  ", -1)
  end
end
