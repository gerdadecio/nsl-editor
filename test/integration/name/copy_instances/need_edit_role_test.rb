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
class NamesCopyInstancesNeedEditRole < ActionDispatch::IntegrationTest
  test "user needs edit role to copy name standalone instances" do
    source_name = names(:angophora_costata)
    target_name = names(:angophora_fred)

    assert_difference("Instance.count", 0) do
      sign_in_as_fake_user(groups: ["login"]) do
        post name_copy_instances_path(id: source_name.id),
          params: {
            name: {
              "target_name_id" => target_name.id.to_s,
              "instance_ids_to_copy" => source_name.standalone_instances.map(&:id),
            },
            "commit" => "Confirm",
          },
          headers: { "Accept" => "text/javascript" }
      end
    end
  end
end
