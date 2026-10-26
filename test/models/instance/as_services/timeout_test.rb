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

# A timeout is an ExceptionWithResponse with no response, so the delete's
# rescue must not call e.response.code on it.
class InstanceDeleteServiceTimeoutTest < ActiveSupport::TestCase
  setup do
    stub_request(:delete, %r{rest/instance/apni/408/api/delete}).to_timeout
  end

  test "instance delete service timeout raises the timeout as a Services error" do
    exception = assert_raise(RuntimeError, "Should raise runtime exception for a timeout") do
      Instance::AsServices.delete(408)
    end
    assert_match "from Services: Timed out", exception.message, "Wrong message"
  end
end
