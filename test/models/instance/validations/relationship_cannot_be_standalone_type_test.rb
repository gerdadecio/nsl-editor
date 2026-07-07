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
class RelationshipCannotBeStandaloneTypeTest < ActiveSupport::TestCase
  test "synonymy instance cannot have a standalone instance type" do
    # Built fresh rather than reusing an existing synonymy fixture: several
    # of the synonymy fixtures for angophora_costata/metrosideros_costata
    # already trip name_cannot_be_double_synonym against each other, which
    # has nothing to do with the validation under test here.
    cited_by_target = instances(:gaertner_created_metrosideros_costata)
    cites_target = instances(:britten_created_angophora_costata)
    synonymy_instance = Instance.new(
      instance_type: instance_types(:basionym),
      this_is_cited_by: cited_by_target,
      this_cites: cites_target,
      reference: cited_by_target.reference,
      name: cites_target.name,
      page: "synonymy instance cannot have a standalone instance type",
      created_by: "tester",
      updated_by: "tester"
    )
    # Bypasses the unrelated "changing an accepted concept's synonymy"
    # warning, which isn't what this test is about.
    synonymy_instance.concept_warning_bypassed = true
    assert synonymy_instance.synonymy?,
           "Precondition: instance must be a synonymy instance."
    assert synonymy_instance.valid?,
           "Starting synonymy instance must be valid for this test; errors:
           #{synonymy_instance.errors.full_messages.join(';')}"

    synonymy_instance.instance_type = instance_types(:comb_nov)

    assert_not synonymy_instance.valid?,
               "Should not be valid with a standalone instance type."
    assert_includes synonymy_instance.errors.full_messages,
                     "A relationship instance cannot be a standalone type"
  end

  test "unpublished citation instance cannot have a standalone instance type" do
    unpub_cit_instance =
      instances(:rusty_gum_is_a_common_name_of_angophora_costata)
    assert unpub_cit_instance.valid?,
           "Starting unpublished citation instance must be valid; errors:
           #{unpub_cit_instance.errors.full_messages.join(';')}"
    assert unpub_cit_instance.cited_by_id.present?,
           "Precondition: instance must have a cited_by_id."
    assert_nil unpub_cit_instance.cites_id,
               "Precondition: instance must not have a cites_id."

    unpub_cit_instance.instance_type = instance_types(:comb_nov)

    assert_not unpub_cit_instance.valid?,
               "Should not be valid with a standalone instance type."
    assert_includes unpub_cit_instance.errors.full_messages,
                     "A relationship instance cannot be a standalone type"
  end

  test "standalone instance can have a standalone instance type" do
    standalone_instance =
      instances(:britten_created_angophora_costata)
    assert standalone_instance.cited_by_id.blank?,
           "Precondition: instance must not have a cited_by_id."
    assert standalone_instance.instance_type.standalone?,
           "Precondition: instance type must be standalone."

    assert standalone_instance.valid?,
           "Standalone instance with standalone type should be valid; errors:
           #{standalone_instance.errors.full_messages.join(';')}"
  end
end
