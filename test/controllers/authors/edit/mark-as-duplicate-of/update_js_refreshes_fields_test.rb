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

# After a save, update.js.erb refreshes both Duplicate of fields - the
# visible text and the hidden id - so a later save doesn't resolve against
# a stale id left in the hidden field.
class AuthorEditMarkAsDuplicateOfUpdateJsTest < ActionDispatch::IntegrationTest
  def update_author(author, typeahead_text, duplicate_of_id)
    sign_in_as_fake_user(
      username: "fred",
      full_name: "Fred Jones",
      groups: [ "edit" ]
    ) do
      patch author_path(author),
        params: {
          author: {
            "name" => author.name,
            "duplicate_of_typeahead" => typeahead_text,
            "duplicate_of_id" => duplicate_of_id,
          },
        },
        headers: { "Accept" => "application/javascript" }
    end
  end

  test "should set the hidden id to the new duplicate of" do
    master = authors(:clarke_1)
    author = authors(:clarke_2)

    update_author(author, master.name, master.id)

    assert_response :success
    assert_includes response.body,
                    "$('input#author_duplicate_of_id').val('#{master.id}');"
  end

  test "should clear the hidden id when duplicate of is removed" do
    master = authors(:clarke_1)
    author = authors(:clarke_2)
    author.update!(duplicate_of_id: master.id)

    update_author(author, "", master.id)

    assert_response :success
    assert_nil author.reload.duplicate_of_id
    assert_includes response.body, "$('input#author_duplicate_of_id').val('');"
    assert_includes response.body,
                    "$('input#author-duplicate-of-typeahead').val('');"
  end

  # The name is JS-escaped, so an apostrophe can't end the string early, but
  # not HTML-escaped, which .val() would show literally as "O&#39;Brien".
  test "should js-escape but not html-escape the duplicate of name" do
    master = authors(:clarke_1)
    master.update!(name: "O'Brien")
    author = authors(:clarke_2)

    update_author(author, "O'Brien", master.id)

    assert_response :success
    assert_includes response.body, "val('O\\'Brien')"
  end
end
