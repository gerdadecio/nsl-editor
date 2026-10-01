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
class ReferenceDestroyForEditorSimpleTest < ActionDispatch::IntegrationTest
  setup do
    @reference = references(:simple)
  end

  #  assert_difference('Reference.count') do
  test "editor should destroy reference not associated to a product" do
    @reference.products.update_all(reference_id: nil)
    assert_difference(
      "Reference.count",
      -1,
      "References should reduce by 1 when editor destroys 1"
    ) do
      sign_in_as_fake_user(
        username: "fred",
        full_name: "Fred Jones",
        groups: ["edit"]
      ) do
        delete reference_path(id: @reference.id),
          headers: { "Accept" => "application/javascript" }
      end
    end
    assert_response :success, "Editor should be able to destroy reference"
  end
end
