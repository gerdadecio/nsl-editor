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
class InstancesCreateStandaloneByEditorTest < ActionDispatch::IntegrationTest
  test "editor should be able to create standalone" do
    name = names(:a_species)
    reference = references(:a_book)
    instance_type = instance_types(:secondary_reference)
    instance_params = {
      "instance_type_id" => instance_type.id,
      "page" => "62",
      "verbatim_name_string" => "",
      "bhl_url" => "",
      "name_id" => name.id,
      "reference_id" => reference.id,
      "extra_primary_override" => "0",
    }
    assert_difference("Instance.count") do
      sign_in_as_fake_user(
        username: "fred",
        full_name: "Fred Jones",
        groups: [ "edit" ]
      ) do
        post instances_path,
          params: { instance: instance_params },
          headers: { "Accept" => "application/javascript" }
      end
    end
    assert_response :success
  end
end
