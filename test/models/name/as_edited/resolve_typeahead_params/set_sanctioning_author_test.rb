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

# Single name model test.
class NameAsEdResolveTheadParamsSetSanctAuthorTest < ActiveSupport::TestCase
  test "name as edited resolve typeahead params set sanctioning author" do
    dummy = authors(:dummy_author_1)
    name = Name::AsEdited.find(names(:has_no_authors).id)
    assert name.sanctioning_author_id.blank?,
           "Name should be have no sanctioning author to start this test."
    name.resolve_typeahead_params(
      "sanctioning_author_id" => dummy.id,
      "sanctioning_author_typeahead" => dummy.abbrev
    )
    assert_equal dummy.id,
                 name.sanctioning_author_id,
                 "Should now have an sanctioning author id"
  end
end
