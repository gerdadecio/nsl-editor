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
class InstancesChangeReferenceForEditorSimpleTest < ActionDispatch::IntegrationTest
  test "editor should be able to change instance reference" do
    instance = instances(:triodia_in_brassard)
    reference = references(:a_book)
    assert instance.reference_id != reference.id
    sign_in_as_fake_user(
      username: "fred",
      full_name: "Fred Jones",
      groups: [ "edit" ]
    ) do
      patch change_instance_reference_path(id: instance.id),
        params: { instance: { "reference_id" => reference.id } },
        headers: { "Accept" => "application/javascript" }
    end
    assert_response :success
    assert Instance.find(instance.id).reference_id == reference.id
  end
end
