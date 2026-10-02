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

# A soft deleted instance must never be offered in the typeahead.
class InstTAhead4NameShowRefToUpdExcludesSoftDeletedTest < ActionDispatch::IntegrationTest
  test "editor typeahead excludes soft deleted instances" do
    instance = instances(:xyz_costata_is_synonym_of_angophora_costata)
    before = typeahead_ids(instance)
    assert before.any?, "Search should have results."

    soft_deleted_id = before.first
    Instance.find(soft_deleted_id).update_column(:deleted_at, Time.current)

    after = typeahead_ids(instance)
    assert_not_includes after, soft_deleted_id
    assert_equal before.size - 1, after.size
  end

  private

  def typeahead_ids(instance)
    sign_in_as_fake_user(
      username: "fred",
      full_name: "Fred Jones",
      groups: [ "edit" ]
    ) do
      get typeahead_for_name_showing_references_to_update_instance_path(
        term: "an",
        instance_id: instance.id
      ),
        headers: { "Accept" => "application/javascript" }
    end
    assert_response :success
    JSON.parse(response.body).pluck("id")
  end
end
