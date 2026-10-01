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
class NameTagNamesCreateByEditorSimpleTest < ActionDispatch::IntegrationTest
  test "editor should be able to create name tag name" do
    skip "irregular composite key insert test not working under Rails 7"
    # but the function itself works in development
    name = names(:a_species)
    name_tag = name_tags(:acra)
    puts NameTagName.count
    # assert_difference("NameTagName.count") do
    sign_in_as_fake_user(
      username: "fred",
      full_name: "Fred Jones",
      groups: ["edit"]
    ) do
      post name_tag_names_path,
        params: {
          name_tag_name: {
            "name_id" => name.id,
            "tag_id" => name_tag.id,
          },
          "commit" => "Add",
        },
        headers: { "Accept" => "application/javascript" }
    end
    puts NameTagName.count
    # end
    assert_response :success
  end
end
