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
class NamesCreateWithInvalidAuthorTest < ActionController::TestCase
  tests NamesController

  test "editor create name with invalid author" do
    @request.headers["Accept"] = "application/javascript"
    assert_no_difference("Name.count") do
      post(:create,
           params: { name: { "name_status_id" => name_statuses(:legitimate),
                             "name_rank_id" => name_ranks(:species),
                             "name_type_id" => name_types(:scientific),
                             "author_id" => nil,
                             "author_typeahead" => "aabasdb",
                             "name_element" => "fred" } },
           session: { username: "fred",
                      user_full_name: "Fred Jones",
                      groups: ["edit"] })
    end
    # can we check for error message?
  end
end
