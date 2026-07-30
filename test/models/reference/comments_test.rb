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

# Tests for Reference#comments?
class ReferenceCommentsTest < ActiveSupport::TestCase
  test "comments? is true when reference has a comment" do
    assert references(:handbook_of_the_vascular_plants_of_sydney).comments?,
           "Should be true when reference has a comment"
  end

  test "comments? is false when reference has no comments" do
    assert_not references(:simple).comments?,
               "Should be false when reference has no comments"
  end
end
