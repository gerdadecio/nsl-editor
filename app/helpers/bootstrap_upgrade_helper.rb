# frozen_string_literal: true

# Helpers supporting the Bootstrap 3.3.7 -> 5.3.8 upgrade, gated behind the
# `Rails.configuration.use_latest_bootstrap_version` feature flag.
#
# The flag is set in the external editor config file as:
#   Rails.configuration.use_latest_bootstrap_version = true
#
# When the BS3 fallback is eventually removed, this whole helper (and its
# callers) can be deleted.
module BootstrapUpgradeHelper
  # True when the Bootstrap 5 feature flag is on. `try` keeps this nil-safe if
  # the config predates the flag.
  def bootstrap5?
    Rails.configuration.try(:use_latest_bootstrap_version) == true
  end

  # Emits the correct Bootstrap data attributes for the active major version.
  # Bootstrap 5 renamed data-toggle/data-target to data-bs-toggle/data-bs-target.
  #   <a <%= bs_toggle(:dropdown) %>>
  #   <button <%= bs_toggle(:collapse, target: ".navbar-collapse") %>>
  def bs_toggle(kind, target: nil)
    prefix = bootstrap5? ? "data-bs" : "data"
    attrs = %(#{prefix}-toggle="#{kind}")
    attrs += %( #{prefix}-target="#{target}") if target
    attrs.html_safe
  end

  # Navbar toggler button class (renamed navbar-toggle -> navbar-toggler in BS5).
  def navbar_toggle_class
    bootstrap5? ? "navbar-toggler" : "navbar-toggle"
  end
end
