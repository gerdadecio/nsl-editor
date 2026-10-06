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

# See references_test.rb in this folder. A reader is granted
# can("authors", "tab_show_1"). AuthorsController#update has its own
# check, but create and destroy do not.
class TabParamBypassAuthorsTest < ActionDispatch::IntegrationTest
  test "reader cannot create an author by adding a permitted tab param" do
    assert_no_difference("Author.count") do
      sign_in_as_fake_user(username: "fred", full_name: "Fred Jones", groups: []) do
        post authors_path(tab: "tab_show_1"),
          params: { author: { "name" => "Reader Created", "abbrev" => "ReaderCr." } },
          headers: { "Accept" => "application/javascript" }
      end
    end
    assert_response :forbidden
  end

  test "reader cannot destroy an author by adding a permitted tab param" do
    # A copy of a fixture author with nothing referencing it, so if the gate is
    # bypassed the delete really succeeds (rather than hitting a foreign key).
    author = authors(:dash).dup
    author.name = "Disposable Author"
    author.abbrev = "Disposable"
    author.save!
    sign_in_as_fake_user(username: "fred", full_name: "Fred Jones", groups: []) do
      delete author_path(id: author.id, tab: "tab_show_1"),
        headers: { "Accept" => "application/javascript" }
    end
    assert_response :forbidden
    assert Author.exists?(author.id)
  end
end
