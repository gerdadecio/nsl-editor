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
require "minitest/mock"

# ServicesHttp wraps RestClient so every call to Services gets explicit open
# and read timeouts, and gives a way to log Services URLs without the API key.
class ServicesHttpTest < ActiveSupport::TestCase
  def capture_execute_args
    captured = nil
    RestClient::Request.stub(:execute, ->(**args) { captured = args; "ok" }) do
      yield
    end
    captured
  end

  test "get sets the open timeout and the default read timeout" do
    args = capture_execute_args { ServicesHttp.get("http://s/x", { accept: :json }) }

    assert_equal :get, args[:method]
    assert_equal "http://s/x", args[:url]
    assert_equal({ accept: :json }, args[:headers])
    assert_equal ServicesHttp::OPEN_TIMEOUT, args[:open_timeout]
    assert_equal ServicesHttp::READ_TIMEOUT, args[:read_timeout]
    assert_not args.key?(:payload)
  end

  test "a read timeout is passed through when given" do
    args = capture_execute_args { ServicesHttp.get("http://s/x", {}, read_timeout: 5) }

    assert_equal 5, args[:read_timeout]
    assert_equal ServicesHttp::OPEN_TIMEOUT, args[:open_timeout]
  end

  test "post and put send the payload" do
    %i[post put].each do |method|
      args = capture_execute_args { ServicesHttp.public_send(method, "http://s/x", "{}", { content_type: :json }) }

      assert_equal method, args[:method]
      assert_equal "{}", args[:payload]
      assert_equal ServicesHttp::OPEN_TIMEOUT, args[:open_timeout]
      assert_equal ServicesHttp::READ_TIMEOUT, args[:read_timeout]
    end
  end

  test "delete sets the open and read timeouts" do
    args = capture_execute_args { ServicesHttp.delete("http://s/x", { accept: :json }) }

    assert_equal :delete, args[:method]
    assert_equal ServicesHttp::OPEN_TIMEOUT, args[:open_timeout]
    assert_equal ServicesHttp::READ_TIMEOUT, args[:read_timeout]
  end

  test "loggable hides the API key wherever it is in the query string" do
    assert_equal "http://s/api/x?apiKey=[FILTERED]&as=fred",
                 ServicesHttp.loggable("http://s/api/x?apiKey=secret-123&as=fred")
    assert_equal "http://s/1/api/delete?reason=Edit&apiKey=[FILTERED]",
                 ServicesHttp.loggable("http://s/1/api/delete?reason=Edit&apiKey=secret-123")
  end

  test "loggable leaves URLs without an API key alone" do
    assert_equal "http://s/1/api/apni", ServicesHttp.loggable("http://s/1/api/apni")
    assert_equal "", ServicesHttp.loggable(nil)
  end
end
