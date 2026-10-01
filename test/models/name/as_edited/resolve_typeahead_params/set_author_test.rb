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
class NameAsEditedResolveTypeaheadParamsSetAuthorTest < ActiveSupport::TestCase
  test "name as edited revolve typeahead params set author" do
    dummy_author = authors(:dummy_author_1)
    name = Name::AsEdited.find(names(:has_no_authors).id)
    assert name.author_id.blank?,
           "Name should be have no author to start this test."
    name.resolve_typeahead_params(
      "author_id" => dummy_author.id,
      "author_typeahead" => dummy_author.abbrev
    )
    assert_equal dummy_author.id,
                 name.author_id,
                 "Should now have an author id"
  end
end
