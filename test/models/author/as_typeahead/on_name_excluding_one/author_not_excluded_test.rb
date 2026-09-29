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

# Single author model test.
class AuthorAsTypeaheadOnNameExcludingOneSimpleTest < ActiveSupport::TestCase
  test "haeckel not excluded" do
    result = Author::AsTypeahead.on_name_duplicate_of(
      "haeck",
      authors(:haeckel).id + 1
    )
    assert_equal 1, result.size, "Expecting 1 record for 'haeck'."
    ids = result.collect { |author| author[:id] }
    assert ids.include?(authors(:haeckel).id.to_s), "Expecting Haeckel's id."
  end
end
