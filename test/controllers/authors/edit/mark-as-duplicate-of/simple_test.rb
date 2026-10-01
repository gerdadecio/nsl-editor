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

# Single controller test.
class AuthorEditMarkAsDuplicateOfSimpleTest < ActionDispatch::IntegrationTest
  test "update author to be duplicate of simple" do
    author = authors(:clarke_1)
    intended_dupe = authors(:clarke_2)
    sign_in_as_fake_user(
      username: "fred",
      full_name: "Fred Jones",
      groups: ["edit"]
    ) do
      patch author_path(intended_dupe),
        params: {
          author: {
            "name" => "Clarke",
            "duplicate_of_typeahead" => "Clarke",
            "duplicate_of_id" => author.id,
          },
        },
        headers: { "Accept" => "application/javascript" }
    end
    assert_response :success
    expected_dupe = Author.find(intended_dupe.id)
    assert_equal author.id, expected_dupe.duplicate_of_id, "Should be equal."
  end
end
