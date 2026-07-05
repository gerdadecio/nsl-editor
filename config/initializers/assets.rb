# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path

# Vendored Bootstrap 5 CSS (loaded only when
# Rails.configuration.use_latest_bootstrap_version is true).
Rails.application.config.assets.paths << Rails.root.join("vendor", "assets", "stylesheets")
Rails.application.config.assets.precompile += %w[bootstrap.min.css]

# Precompile the BS3->BS5 compatibility shim (loaded only when the
# use_latest_bootstrap_version flag is on). The vendor stylesheet path it
Rails.application.config.assets.precompile += %w[bootstrap5-compat.css]
