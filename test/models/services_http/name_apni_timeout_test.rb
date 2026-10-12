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

# The APNI lookups for a name were meant to time out quickly, but passed
# read_timeout inside the headers hash, so RestClient sent it as a
# "Read-Timeout" header and waited the full default 60 seconds.
class NameApniTimeoutTest < ActiveSupport::TestCase
  def capture_execute_args(body)
    captured = nil
    RestClient::Request.stub(:execute, ->(**args) { captured = args; body }) do
      yield
    end
    captured
  end

  test "the in-APNI lookup uses a real 5 second read timeout" do
    args = capture_execute_args('{"inAPNI":true}') { names(:a_genus).apni_json }

    assert_equal 5, args[:read_timeout]
    assert_equal ServicesHttp::OPEN_TIMEOUT, args[:open_timeout]
    assert_equal({ "Accept" => "text/json" }, args[:headers])
  end

  test "the APNI family lookup uses a real 5 second read timeout" do
    args = capture_execute_args('{"familyName":null}') { names(:a_genus).apni_family_json }

    assert_equal 5, args[:read_timeout]
    assert_equal({ "Accept" => "text/json" }, args[:headers])
  end

  test "a slow APNI service means not in APNI, rather than an error" do
    stub_request(:get, %r{api/apni}).to_timeout

    assert_equal false, names(:a_genus).apni?
  end
end
