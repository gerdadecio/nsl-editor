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

# Name tag name test
class NeedsUpdatedBy < ActiveSupport::TestCase
  test "check" do
    acra = name_tags(:acra)
    a_species = names(:a_species)
    name_tag_name = NameTagName.new(
      name_id: a_species.id,
      tag_id: acra.id,
      created_by: "tester",
    )
    assert_not name_tag_name.valid?,
      "Name Tag Name record should not be valid without updated_by."
    name_tag_name.updated_by = "tester"
    assert name_tag_name.valid?,
      "Name Tag Name record should now be valid with updated_by."
  end
end
