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
class ServicesController < ApplicationController
  CSP_REPORT_MAX_BYTES = 8.kilobytes
  CSP_REPORT_MAX_VALUE_LENGTH = 300

  skip_before_action :authenticate
  # Browsers post CSP reports without a CSRF token.
  skip_forgery_protection only: :csp_report
  rate_limit to: 60, within: 1.minute, only: :csp_report, with: -> { head :too_many_requests }

  def ping
    render(plain: "✓", status: :ok, layout: false)
  end

  def version
    render(
      plain: "#{Rails.configuration.try("version")}",
      status: :ok,
      layout: false,
    )
  end

  def build
    render(
      partial: "build",
      format: :text,
      status: :ok,
      layout: false,
    )
  end

  def clear_connections
    ActiveRecord::Base.clear_active_connections!
    render(plain: "Cleared.", status: :ok, layout: false)
  end

  # Receives Content Security Policy violation reports from browsers
  # (see config/initializers/content_security_policy.rb) and logs them.
  def csp_report
    report = parse_csp_report
    logger.warn("CSP violation: #{report.to_json}") if report.present?
    head :no_content
  end

  private

  def parse_csp_report
    data = JSON.parse(request.body.read(CSP_REPORT_MAX_BYTES).to_s)
    data = data["csp-report"] if data.is_a?(Hash)
    return if !data.is_a?(Hash)

    {
      directive: data["effective-directive"] || data["violated-directive"],
      blocked: without_query(data["blocked-uri"]),
      page: without_query(data["document-uri"]),
      source: without_query(data["source-file"]),
      line: data["line-number"],
    }.compact.transform_values { |value| value.to_s.truncate(CSP_REPORT_MAX_VALUE_LENGTH) }
  rescue JSON::ParserError
    nil
  end

  # Query strings can hold search terms and other user input, so leave them out of the log.
  def without_query(uri)
    uri&.to_s&.split(/[?#]/, 2)&.first
  end
end
