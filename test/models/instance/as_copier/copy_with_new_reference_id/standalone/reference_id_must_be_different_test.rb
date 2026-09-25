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
class InstanceAsCopierWithNewRefStandaloneRefMustBeDiffTest <
  ActiveSupport::TestCase
  test "copy a standalone instance with its citations ref must be different" do
    master_instance = Instance::AsCopier.find(
      instances(:gaertner_created_metrosideros_costata).id,
    )
    assert_not master_instance.citations.empty?,
      "Master instance should have at least 1 citation."
    dummy_username = "fred"
    params = ActionController::Parameters.new(
      reference_id: master_instance.reference.id.to_s,
    )
    assert_raises RuntimeError, "Should not allow copy to same reference id." do
      master_instance.copy_with_citations_to_new_reference(
        params,
        dummy_username,
      )
    end
  end
end
