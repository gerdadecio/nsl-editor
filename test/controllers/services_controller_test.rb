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

  test "responses carry a report-only content security policy" do
    get ping_service_path
    policy = response.headers["Content-Security-Policy-Report-Only"]
    assert_includes policy, "report-uri /csp-report"
    assert_includes policy, "script-src 'self' 'unsafe-inline'"
    assert_nil response.headers["Content-Security-Policy"]
  end

  test "unauthenticated csp report is logged without query strings" do
    report = {
      "csp-report" => {
        "document-uri" => "https://editor.example/search?query=secret-term",
        "effective-directive" => "script-src-elem",
        "blocked-uri" => "https://evil.example/x.js?token=abc",
      },
    }
    log = capture_controller_log do
      post csp_report_service_path, params: report.to_json,
                                    headers: { "CONTENT_TYPE" => "application/csp-report" }
    end
    assert_response :no_content
    assert_includes log, "CSP violation"
    assert_includes log, "script-src-elem"
    assert_includes log, "https://evil.example/x.js"
    assert_not_includes log, "secret-term"
    assert_not_includes log, "token=abc"
  end

  test "malformed csp report is ignored" do
    log = capture_controller_log do
      post csp_report_service_path, params: "not json",
                                    headers: { "CONTENT_TYPE" => "application/csp-report" }
    end
    assert_response :no_content
    assert_not_includes log, "CSP violation"
  end

  private

  def capture_controller_log
    io = StringIO.new
    original = ActionController::Base.logger
    ActionController::Base.logger = ActiveSupport::Logger.new(io)
    yield
    io.string
  ensure
    ActionController::Base.logger = original
  end
end
