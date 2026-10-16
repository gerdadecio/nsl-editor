# frozen_string_literal: true

#   Copyright 2015 Australian National Botanic Gardens
#   This file is part of the NSL Editor.
#   Licensed under the Apache License, Version 2.0

# Receives Content Security Policy violation reports from browsers
# (see config/initializers/content_security_policy.rb) and logs them.
#
# Based on ActionController::API rather than ApplicationController: the
# endpoint is stateless and needs no sign-in, session, CSRF token or CanCan
# check. Browsers post reports without a CSRF token, and logging a report
# does nothing on a user's behalf.
class CspReportsController < ActionController::API
  MAX_BYTES = 8.kilobytes
  MAX_VALUE_LENGTH = 300

  rate_limit to: 60, within: 1.minute, with: -> { head :too_many_requests }

  def create
    report = parse_report
    logger.warn("CSP violation: #{report.to_json}") if report.present?
    head :no_content
  end

  private

  def parse_report
    data = JSON.parse(request.body.read(MAX_BYTES).to_s)
    data = data["csp-report"] if data.is_a?(Hash)
    return if !data.is_a?(Hash)

    {
      directive: data["effective-directive"] || data["violated-directive"],
      blocked: without_query(data["blocked-uri"]),
      page: without_query(data["document-uri"]),
      source: without_query(data["source-file"]),
      line: data["line-number"],
    }.compact.transform_values { |value| value.to_s.truncate(MAX_VALUE_LENGTH) }
  rescue JSON::ParserError
    nil
  end

  # Query strings can hold search terms and other user input, so leave them out of the log.
  def without_query(uri)
    uri&.to_s&.split(/[?#]/, 2)&.first
  end
end
