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

# Services URLs carry the API key in the query string (apiKey=...). The
# callers log the URL they call; the key must not end up in the log.
class ServicesApiKeyNotLoggedTest < ActiveSupport::TestCase
  API_KEY = Rails.configuration.try("api_key")

  def capture_log
    io = StringIO.new
    logger = ActiveSupport::Logger.new(io)
    old_rails, old_ar = Rails.logger, ActiveRecord::Base.logger
    Rails.logger = ActiveRecord::Base.logger = logger
    yield
    io.string
  ensure
    Rails.logger = old_rails
    ActiveRecord::Base.logger = old_ar
  end

  test "the test config has an API key to look for" do
    assert API_KEY.present?
  end

  test "updating excluded status does not log the API key" do
    stub_request(:post, /editElementStatus/).to_return(status: 200, body: "{}")

    log = capture_log do
      Tree::Workspace::Excluded.new(element_link: "/tree/1/2", excluded: true, username: "fred").update
    end

    assert_includes log, "editElementStatus?apiKey=[FILTERED]&as=fred"
    assert_not_includes log, API_KEY
  end

  test "creating a draft does not log the API key" do
    stub_request(:put, /createVersion/).to_return(status: 200, body: "{}")

    log = capture_log do
      Tree::DraftVersion.create_via_service(trees(:APC).id, nil, "draft", "log", false, "fred")
    end

    assert_includes log, "createVersion?apiKey=[FILTERED]&as=fred"
    assert_not_includes log, API_KEY
  end

  test "updating synonymy does not log the API key" do
    stub_request(:post, /update-synonymy-by-event/).to_return(status: 200, body: "{}")

    log = capture_log { Tree::AsServices.update_synonymy("[]", "fred") }

    assert_includes log, "apiKey=[FILTERED]"
    assert_not_includes log, API_KEY
  end

  test "a failed name delete does not log the API key" do
    stub_request(:delete, /api.delete/)
      .to_return(status: 200, body: '{"ok":false,"errors":["Nope"]}')

    log = capture_log do
      assert_raises(RuntimeError) { Name::AsServices.find(names(:name_to_delete).id).delete_with_reason("Testing") }
    end

    assert_includes log, "apiKey=[FILTERED]"
    assert_not_includes log, API_KEY
  end

  test "a failed instance delete does not log the API key" do
    stub_request(:delete, /api.delete/).to_return(status: 500, body: "{}")

    log = capture_log do
      assert_raises(RuntimeError) { Instance::AsServices.delete(instances(:britten_created_angophora_costata).id) }
    end

    assert_includes log, "apiKey=[FILTERED]"
    assert_not_includes log, API_KEY
  end
end
