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
class AuthorEditMESpacesNameCreateWithTest < ActionDispatch::IntegrationTest
  test "name created with multiple embedded spaces to single space" do
    author_name = "j   jjjjjj"
    author_abbrev = "ff  x    r"
    assert_difference("Author.count", 1) do
      sign_in_as_fake_user(
        username: "fred",
        full_name: "Fred Jones",
        groups: [ "edit" ]
      ) do
        post authors_path,
          params: {
            author: {
              "name" => author_name,
              "abbrev" => author_abbrev,
            },
          },
          headers: { "Accept" => "application/javascript" }
      end
      assert_not_nil assigns(:author), "Should assign author"
      new_author = Author.find_by(name: author_name.gsub(/  +/, " "))
      assert_match author_name.gsub(/  +/, " "),
                   new_author.name,
                   "New author name should not have embedded spaces"
      assert_match author_abbrev.gsub(/  +/, " "),
                   new_author.abbrev,
                   "New author abbrev should not have embedded spaces"
    end
  end
end
