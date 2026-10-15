# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header
#
# The policy is in report-only mode: browsers block nothing, they only post
# violations to /csp-report (CspReportsController#create), which logs them.
# Use the logged violations to fix the policy or the page before enforcing it.
#
# 'unsafe-inline' is needed for scripts because of the inline <script> blocks,
# inline event handlers and .js.erb (UJS) responses, and for styles because of
# inline style attributes and the styles Font Awesome injects.
#
# No nonce generator is set on purpose: a browser that sees a nonce in
# script-src ignores 'unsafe-inline', so every inline script would be reported.

Rails.application.configure do
  script_hosts = %w[
    https://cdn.jsdelivr.net
    https://cdnjs.cloudflare.com
    https://unpkg.com
    https://ga.jspm.io
    https://kit.fontawesome.com
  ]

  # The Font Awesome kit fetches its CSS (connect-src) and fonts from ka-f.fontawesome.com.
  style_hosts = %w[
    https://maxcdn.bootstrapcdn.com
    https://cdn.jsdelivr.net
    https://cdnjs.cloudflare.com
    https://ka-f.fontawesome.com
  ]

  font_hosts = %w[
    https://maxcdn.bootstrapcdn.com
    https://ka-f.fontawesome.com
  ]

  config.content_security_policy do |policy|
    policy.default_src :self
    policy.script_src  :self, :unsafe_inline, *script_hosts
    policy.style_src   :self, :unsafe_inline, *style_hosts
    policy.font_src    :self, :data, *font_hosts
    policy.img_src     :self, :data, :https
    policy.connect_src :self, "https://ka-f.fontawesome.com"
    policy.object_src  :none
    policy.base_uri    :self
    policy.form_action :self
    policy.frame_ancestors :self
    policy.report_uri "/csp-report"
  end

  # Report violations without enforcing the policy.
  config.content_security_policy_report_only = true
end
