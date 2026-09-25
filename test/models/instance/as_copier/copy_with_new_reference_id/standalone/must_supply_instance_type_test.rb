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
class InstAsCopierWNewRefSAloneMustSupplyITypeTest < ActiveSupport::TestCase
  test "copy a standalone instance with its citers wo instance type" do
    master_instance = Instance::AsCopier.find(
      instances(:gaertner_created_metrosideros_costata).id,
    )
    assert_not master_instance.citations.empty?,
      "Master instance should have at least 1 citation."
    target_reference = references(:never_used)
    dummy_username = "fred"
    params = ActionController::Parameters.new(
      reference_id: target_reference.id.to_s,
    )
    err_str = "Validation failed: Instance type cannot be empty."
    err = assert_raises(Exception, err_str) do
      master_instance.copy_with_citations_to_new_reference(
        params, dummy_username
      )
    end
    assert_equal(err_str, err.message, "Incorrect error message")
  end
end
