def next?
  File.basename(__FILE__) == "Gemfile.next"
end
source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.3.5"

# Bundle edge Rails instead: gem "rails", github: "rails/rails"
if next?
  gem 'rails', '~> 7.1.4.1'
else
  gem "rails", "~> 7.1.4.1"
end

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"

# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"

# Use Puma as the app server [https://github.com/puma/puma]
gem "puma", ">= 6.3.1"

# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"

# Build JSON APIs with ease. [https://github.com/rails/jbuilder]
gem "jbuilder", "~> 2.7"

# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Sass to process CSS
# gem "sassc-rails"

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

gem "listen", ">= 3.0.5", "< 3.2"
group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem "awesome_print"
  gem "web-console", ">= 3.3.0"
  gem "byebug"
  gem "annotaterb"
end

group :test do
  # gem 'capybara', '>= 2.15'
  # gem "selenium-webdriver"
  # Easy installation and use of web drivers to run system tests with browsers
  gem "launchy"
  gem "minitest"
  gem "minitest-rails"
  gem "minitest-reporters"
  # NoMethodError: assert_template has been extracted to a gem. To continue using it, add:
  gem "rails-controller-testing"
end

group :development, :test do
  gem "pry-rails"
  # gem "pry-rescue" # breaks test env. on Mac M1
  gem "webmock"
  # gem "schema_plus"
end

# Added
gem "active_type"
gem "cancancan"
gem "net-ldap"
gem "pg_search"
gem "strip_attributes"
gem "sucker_punch"

gem "exception_notification"
gem "kramdown", ">= 2.3.0"
gem "nokogiri", ">= 1.13.4"
gem "rack", ">= 2.2.3"
gem "rest-client"
gem "simple_calendar", "~> 2.0"
gem "websocket-extensions", ">= 0.1.5"

gem "addressable", ">= 2.8.0"

gem "simplecov", require: false, group: :test

gem "standard", group: %i[development test]
gem "standardrb", group: %i[development test]

gem "csv"
gem "font-awesome-sass", "~> 6.4.0"
gem "rails-ujs"
gem "unf_ext", "< 0.0.9"
gem "indefinite_article"

group :development do
  gem 'brakeman', require: false
  gem 'bundler-audit', require: false
end

gem 'next_rails'
gem 'logger' # previously logger was loaded from the standard library, but will no longer be part of the default gems starting from Ruby 3.5.0.
gem 'ostruct' # previously ostruct was loaded from the standard library, but will no longer be part of the default gems starting from Ruby 3.5.0.

