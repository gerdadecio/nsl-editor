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

# Single instance model test.
#
# Instance#relationship_cannot_have_bhl_url is scoped to instance_type.relationship?
# specifically (not standalone?/cited_by_id), so it also leaves alone
# instance types that are neither standalone nor relationship.
class RelationshipCannotHaveBhlUrlTest < ActiveSupport::TestCase
  test "relationship instance cannot have a bhl_url value" do
    relationship_instance =
      instances(:rusty_gum_is_a_common_name_of_angophora_costata)
    assert relationship_instance.instance_type.relationship?,
           "Precondition: instance type must be a relationship type."
    assert relationship_instance.bhl_url.blank?,
           "Precondition: bhl_url must start blank."
    assert relationship_instance.valid?,
           "Starting relationship instance must be valid for this test; errors:
           #{relationship_instance.errors.full_messages.join(';')}"

    relationship_instance.bhl_url = "https://www.biodiversitylibrary.org/item/1"

    assert_not relationship_instance.valid?,
               "Should not be valid with a bhl_url set."
    assert_includes relationship_instance.errors.full_messages,
                     "A relationship instance cannot have a bhl url value"
  end

  test "standalone instance can have a bhl_url value" do
    standalone_instance = instances(:britten_created_angophora_costata)
    assert_not standalone_instance.instance_type.relationship?,
               "Precondition: instance type must not be a relationship type."

    standalone_instance.bhl_url = "https://www.biodiversitylibrary.org/item/2"

    assert standalone_instance.valid?,
           "Standalone instance with a bhl_url should be valid; errors:
           #{standalone_instance.errors.full_messages.join(';')}"
  end

  test "relationship instance with a blank bhl_url remains valid" do
    relationship_instance =
      instances(:rusty_gum_is_a_common_name_of_angophora_costata)
    relationship_instance.bhl_url = ""

    assert relationship_instance.valid?,
           "Relationship instance with a blank bhl_url should be valid; errors:
           #{relationship_instance.errors.full_messages.join(';')}"
  end
end
