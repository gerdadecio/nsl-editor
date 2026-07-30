# frozen_string_literal: true

require "database_cleaner/active_record"

# The nsl_test DB ships with committed reference data (languages, roles,
# instance_types, name_types, ...). Rails' transactional fixtures roll back the
# rows an example creates but never touch that pre-seeded baseline, which causes
# PG::UniqueViolation when factories try to create those same rows.
#
# So we wipe the database ONCE, before the suite, with DatabaseCleaner. The
# truncation runs as a single statement across all tables, so the schema's
# foreign keys are satisfied without needing CASCADE. After this the database is
# empty and stays that way:
#
# * Per-example isolation is handled by Rails' transactional fixtures
#   (config.use_transactional_fixtures = true in rails_helper.rb) — each example
#   runs in a transaction that is rolled back, which is far faster than cleaning
#   hundreds of tables per example.
# * We deliberately do NOT use DatabaseCleaner's :transaction strategy; it
#   conflicts with Rails 8.1 connection-pool handling.
#
# NOTE: if JS/system specs are added later they commit outside the example
# transaction, so they would need their own truncation (e.g. tag them and switch
# strategy) to stay isolated.
RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end
end
