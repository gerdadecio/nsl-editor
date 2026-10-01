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

# Services controller tests not yet broken into single test files.
class ServicesControllerTest < ActionDispatch::IntegrationTest
  setup do
  end

  test "no user should get index" do
    assert_raises(ActionController::UrlGenerationError) do
      url_for(controller: "services", action: "index", only_path: true)
    end
  end

  test "unauthenticated user should get ping" do
    get ping_service_path
    assert_response :success
  end

  test "unauthenticated user should get build" do
    get build_service_path
    assert_response :success
  end
end
