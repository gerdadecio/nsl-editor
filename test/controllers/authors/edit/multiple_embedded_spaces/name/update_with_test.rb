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
class AuthorEditMESpacesNameUpdateWithTest < ActionController::TestCase
  tests AuthorsController

  test "name updated with multiple embedded spaces to single space" do
    @request.headers["Accept"] = "application/javascript"
    author = authors(:has_multiple_embedded_spaces)
    new_name = "as  asd    x"
    new_abbrev = "as   sd  x"
    patch(:update,
          params: { id: author.id,
                    author: { "name" => new_name,
                              "abbrev" => new_abbrev } },
          session: { username: "fred",
                     user_full_name: "Fred Jones",
                     groups: ["edit"] })
    assert_not_nil assigns(:author), "Should assign author"
    updated_author = Author.find(author.id)
    assert_equal new_name.gsub(/ +/, " "),
                 updated_author.name,
                 "Updated author name should not have embedded spaces"
    assert_match new_abbrev.gsub(/ +/, " "),
                 updated_author.abbrev,
                 "Updated author abbrev should not have embedded spaces"
  end
end
