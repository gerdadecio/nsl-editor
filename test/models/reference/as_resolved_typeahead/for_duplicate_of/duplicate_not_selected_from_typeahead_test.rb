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

# Reference model typeahead test.
class RefARTA4DuplicateOfNotSelectedFromTypeahead < ActiveSupport::TestCase
  test "update reference with duplicate of not selected from typeahead" do
    reference = Reference::AsEdited.first
    assert_raise(
      RuntimeError,
      "Expect error - duplicate of typeahead has value but there is \
                 no duplicate of id.",
    ) do
      reference.update_if_changed(
        {
          "ref_type_id" => ref_types(:section),
          "title" => "ss",
          "published" => "1",
          "ref_author_role_id" => "17281",
          "edition" => "",
          "volume" => "",
          "pages" => "",
          "year" => "",
          "publication_date" => "",
          "notes" => "",
        },
        {
          "duplicate_of_typeahead" => "asdfsa",
          "duplicate_of_id" => "",
          "author_typeahead" => "",
          "author_id" => "",
        },
        "fred",
      )
    end
  end
end
