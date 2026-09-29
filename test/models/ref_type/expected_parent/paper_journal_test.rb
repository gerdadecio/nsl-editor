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

# Ref Type expected parent test.
class PaperShouldHaveJournalParentTest < ActiveSupport::TestCase
  test "paper ref type parent is journal" do
    ref_type = ref_types(:paper)
    # Must have a parent_id to even be in the race with this data structure.
    assert ref_type.parent.name == ref_types(:journal).name,
           "Paper should have journal as parent."
  end
end
