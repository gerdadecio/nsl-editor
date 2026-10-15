# frozen_string_literal: true

#   Copyright 2015 Australian National Botanic Gardens
#   This file is part of the NSL Editor.
#   Licensed under the Apache License, Version 2.0

require "test_helper"

class CspReportsControllerTest < ActionDispatch::IntegrationTest
  test "unauthenticated csp report is logged without query strings" do
    report = {
      "csp-report" => {
        "document-uri" => "https://editor.example/search?query=secret-term",
        "effective-directive" => "script-src-elem",
        "blocked-uri" => "https://evil.example/x.js?token=abc",
      },
    }
    log = capture_controller_log do
      post csp_report_path, params: report.to_json,
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
      post csp_report_path, params: "not json",
                            headers: { "CONTENT_TYPE" => "application/csp-report" }
    end
    assert_response :no_content
    assert_not_includes log, "CSP violation"
  end

  test "csp report does not set a session cookie" do
    post csp_report_path, params: "{}", headers: { "CONTENT_TYPE" => "application/csp-report" }
    assert_response :no_content
    assert_nil response.headers["Set-Cookie"]
  end

  private

  def capture_controller_log
    io = StringIO.new
    original = CspReportsController.logger
    CspReportsController.logger = ActiveSupport::Logger.new(io)
    yield
    io.string
  ensure
    CspReportsController.logger = original
  end
end
