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

# Single reference controller test.
class ReferenceDestroyForbiddenForReaderTest < ActionDispatch::IntegrationTest
  setup do
    @reference = references(:simple)
  end

  test "reader should not be able to destroy a reference" do
    assert_no_difference(
      "Reference.count",
      "No references should be harmed in this test"
    ) do
      sign_in_as_fake_user(
        username: "fred",
        full_name: "Fred Jones",
        groups: []
      ) do
        delete reference_path(id: @reference.id),
          headers: { "Accept" => "application/javascript" }
      end
    end
    assert_response :forbidden, "Reader should not be able to destroy reference"
  end
end
