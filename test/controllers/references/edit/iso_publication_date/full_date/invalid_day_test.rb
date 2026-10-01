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
class ReferencesesUpdateInvalidDayTest < ActionDispatch::IntegrationTest
  setup do
    @msg_part1 = "Publication day, month, year combine to form  *1999-03-32, "
    @msg_part2 = "which is an invalid date"
  end

  test "update reference invalid day" do
    sign_in_as_fake_user(
      username: "fred",
      full_name: "Fred Jones",
      groups: ["edit"]
    ) do
      patch reference_path(id: references(:simple).id),
        params: {
          reference: {
            "ref_type_id" => ref_types(:book).id,
            "title" => "Some book",
            "author_id" => authors(:dash).id,
            "author_typeahead" => "-",
            "published" => true,
            "parent_typeahead" => @parent_typeahead,
            "ref_author_role_id" => ref_author_roles(:author).id,
            "year" => "1999",
            "month" => "3",
            "day" => "32",
          },
        },
        headers: { "Accept" => "application/javascript" }
    end
    assert_response :unprocessable_content
    assert_match(
      /#{@msg_part1}#{@msg_part2}/,
      response.body.to_s,
      "Missing or incorrect error message"
    )
  end
end
