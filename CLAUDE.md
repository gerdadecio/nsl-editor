# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

The **NSL Editor** is a Rails 8 application for editing botanical names and taxonomy data for the Australian National Botanic Gardens (ANBG). It manages databases for Australian plants (APNI), Algae, Fungi, Lichen, and Moss, each in separate PostgreSQL databases sharing a common NSL schema.

- **Ruby**: 3.4.8 (see `.ruby-version`)
- **Rails**: 8.1.x
- **PostgreSQL**: 15.7
- **Time Zone**: Australia/Melbourne
- **App server / assets**: Puma; Sprockets with Importmap
- **Key gems**: `cancancan`, `net-ldap`, `pg_search`, `strip_attributes`, `sucker_punch` (background jobs), `rest-client`, `kramdown`, `bullet` (N+1 detection in development, enabled with `BULLET_ENABLED`)

### Key Domain Concepts

- **Names**: Botanical names with hierarchical parent relationships (genus → species → variety), a second parent for hybrid formulas, and several author roles (author, base author, ex author, ex-base author, sanctioning author)
- **References**: Publications (books, journals, articles) that validate nomenclatural acts. Hierarchical via a parent reference, with an ISO publication date and optional DOI
- **Instances**: The link between a name and a reference, representing a nomenclatural act
- **Taxonomy**: Trees of accepted classifications, with draft and published versions made up of tree elements
- **Authors**: Botanical authors, cited in several roles on names and references

## Build/Test/Lint Commands

```bash
# All Minitest
bundle exec rails test

# Single Minitest file / specific line
bundle exec rails test test/models/author_test.rb
bundle exec rails test test/models/author_test.rb:25

# All RSpec
bundle exec rspec

# Single RSpec file / specific line
bundle exec rspec spec/models/name_spec.rb
bundle exec rspec spec/models/name_spec.rb:10

# Linting
bin/rubocop                # RuboCop linter
bin/brakeman               # Security scanner
bundle exec annotaterb models --exclude tests,spec  # Update model annotations
bundle exec bundle-audit   # Dependency vulnerability audit

# Development
bin/setup            # Full setup (git hooks, bundle, db, cleanup), then starts the server (--skip-server to skip)
bin/dev              # Start dev server
bundle install       # Install dependencies
```

### Running in Docker

The app can also run in Docker (`Dockerfile.dev`, `docker-compose.dev.yml`; see "Setup with Docker" in `README.md`). If the developer is using Docker, run the commands above inside the app container rather than on the host:

```bash
docker-compose -f docker-compose.dev.yml build
docker-compose -f docker-compose.dev.yml up -d
docker-compose -f docker-compose.dev.yml exec app_dev bundle exec rails test
```

Container and service names differ when the Editor runs as part of the wider `docker-apps` stack, so check the compose file in use.

## External Configuration (Required)

These files are not in the repo and must be acquired:
- `~/.nsl/editor-database.yml` - Database credentials
- `~/.nsl/development/editor-r7-config.rb` - App config (auth, services endpoints)

## Sensitive Files - Do Not Read

Never read, display, or log the contents of files that hold credentials. If a task needs to know how one is structured, ask the developer to describe the non-sensitive parts or provide a sanitized example.

- `.env`, `.env.*`
- `~/.nsl/*` and any `.nsl` directory (the external configuration above)
- `.pgpass`, and any `database.yml` containing passwords
- `config/master.key`, `config/*.key`, `credentials.yml.enc`, `secrets*.yml`
- `*.pem`, `*.key`, `*.crt`, `*.p12`, SSH keys (`id_rsa`, `id_ed25519`)
- `vpn/`, `*.ovpn`
- Anything else likely to contain API keys, tokens, or passwords

Never commit secrets, and keep secrets and personal data out of logs.

## Code Style

### File Header

Every Ruby file starts with the frozen string literal comment (RuboCop enforces it). New files should also carry the Apache 2.0 license header. Nothing checks for the license, and some existing files lack it, but most have it (often the full license text rather than this short form):

```ruby
# frozen_string_literal: true

#   Copyright 2015 Australian National Botanic Gardens
#   This file is part of the NSL Editor.
#   Licensed under the Apache License, Version 2.0
```

### Formatting Rules

| Rule | Guideline |
|------|-----------|
| Strings | Double quotes: `"string"` not `'string'` |
| Trailing commas | Multiline hashes: yes. Arrays: no |
| Line/method length | No limits (disabled) |
| `unless` | Never with `&&`/`\|\|`. Use `if !condition` |

### Conventions Nothing Enforces

The formatting rules above are RuboCop cops, run by the pre-commit hook (CI does not run RuboCop). The rules below are not: Omakase leaves `Lint/Debugger`, `Rails/Output`, `Rails/FindEach` and `Rails/UniqBeforePluck` disabled, so follow them by hand:

- **No `binding.pry` or `debugger`** statements
- **No `puts` debugging** in app code
- Use `find_each` over `each` for AR collections
- Use `distinct.pluck` not `pluck.uniq`

## Architecture

### Database

- **No migrations** - Schema managed externally via `structure.sql`
- All tables share sequence: `nsl_global_seq`
- Designed for low-privilege CRUD user in production

### Model Conventions

```ruby
class MyModel < ApplicationRecord
  self.table_name = "my_table"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"  # Shared sequence

  include SoftDeletable  # Use concerns for shared behavior
end
```

- Concerns live in `app/models/concerns/`. Model-specific ones are namespaced by model (`Name::Scopable`, `Name::Validatable`, `Name::Parentable` in `concerns/name/`)
- `ApplicationRecord` auto-strips whitespace via `strip_attributes`
- Schema annotations managed by `annotaterb` gem

### Service Object Pattern

```ruby
class MyService < BaseService
  def initialize(params, options = nil)
    @params = params
    @options = options
    @logger = Rails.logger
  end

  def execute
    # Must override - raises NotImplementedError by default
  end
end

# Usage
MyService.call(params, options)
MyService.new_call_transaction(params)  # With rollback on errors
```

### Authorization

- LDAP/SimpleAD for authentication
- CanCanCan for authorization (`current_user`, `current_ability`)
- Database-backed roles for batch reviewers, products, profiles

### Search System

The search mechanism is critical - one unified page for all searches using custom directives. Two engines exist:

1. **Old engine**: targets with their own `base.rb`, `predicate.rb`, `where_clauses.rb`, etc. (`search/on_name/`, `search/on_instance/`). Name search rules are loaded from `config/name-searches.yml`
2. **New generic engine** (`Search::OnModel::Base`): each enrolled target (author, reference, org, user, loader/batch) has just a `field_rule.rb` (a Ruby `RULES` hash mapping directives to SQL) and a `field_abbrev.rb`

See the "Search Mechanism" section of `README.md` for the overview and diagram. `doco/search-engine.md` is meant to hold the detail but is still mostly a placeholder.

### External Dependencies

The Editor relies on NSL Services and Mapper apps for name construction, taxonomy operations, and certain deletes.

- **NSL Services**: name construction and validation, taxonomy tree operations
- **NSL Mapper**: URI generation and resolution
- Calls go through `rest-client`. Handle the service being unavailable, and log failures without leaking credentials

## Testing

Two frameworks run side by side:

- **`test/`**: Minitest with YAML fixtures. `fixtures :all` loads every fixture in alphabetical order, so fixtures must keep referential integrity
- **`spec/`**: RSpec with FactoryBot factories (in `test/factories/`)
- External service calls (NSL Services, Mapper) are stubbed with WebMock, so tests never need those apps running
- Shared Minitest helpers are in `test/test_helper.rb`, e.g. `fill_in_typeahead`, `make_sure_details_are_showing`, `search_result_must_include_content`
- Cover permissions and authorization as well as the happy path and edge cases

## Common Development Tasks

### Adding a model
1. The table is added to the schema externally (it arrives via `structure.sql`, not a migration)
2. Create the model following the conventions above, with concerns for shared behavior
3. Add associations and validations, then fixtures and/or factories
4. Add search configuration if the records need to be searchable

### Extending search
1. Add field rules under `app/models/search/`, in whichever engine the target uses (see Search System above)
2. Keep SQL fragments in the whitelisted maps and bind user values with `?`
3. Test with a range of search directives

## After Every Change

Check the change against these before calling it done:

- **SQL injection**: queries parameterized, no interpolated user input
- **XSS**: user and stored data escaped or passed through `sanitize(...)`, not `.html_safe`
- **N+1 queries**: `includes`/`preload` on associations used in loops and views
- **Authorization**: new actions covered by CanCanCan abilities
- **Sensitive data**: no secrets or personal data in logs

Common gotchas:

- Foreign keys, triggers, and constraints are enforced by the database, so saves and deletes can fail there even when model validations pass
- Search and typeahead queries can be expensive, and large result sets need pagination

## Git Workflow

This repo is a fork. The workflow for changes is:
1. Create a local branch
2. Commit changes and push to origin (your fork)
3. Create a PR on GitHub to the upstream repo

**Post-merge git cleanup** (after PR is merged):
```bash
git fetch upstream
git checkout main
git merge upstream/main
git push
git branch -d <branch-name>
```

**Skills** (in `.claude/skills/`) automate these steps:
- `/git-branch-workflow-set-up`: branch and commit, then hand back. The developer reviews, pushes, and creates the PR (using the PR template)
- `/change-history-and-version`: add a `config/history/changes-YYYY.yml` entry and bump `config/version.properties` (user-facing changes only)
- `/post-merge-clean-up`: sync `main` with upstream after a merge, and delete the branch locally and on the fork

Two more skills review code rather than automate the git workflow. Both are read-only, take a file or directory (defaulting to the current branch's changes), and group findings by severity:
- `/ruby-review`: Ruby best practices, design, performance, and maintainability
- `/security-review`: security vulnerabilities, checked against the Security Review section below

## Git Hooks

Run `bin/setup` or `git config core.hooksPath .githooks` to enable:

- **pre-commit**: Blocks Bootstrap 3/4 classes on added lines; runs RuboCop on staged Ruby files. RuboCop runs in a running editor container if there is one (`nsl_editor_source`, then `nsl_app_dev`), otherwise with the local bundle. Override with `RUBOCOP_RUNNER=docker|local` or `RUBOCOP_CONTAINER=<name>`
- **pre-push**: Confirmation before pushing to main/master

Override options:
```bash
SKIP_RUBOCOP=1 git commit -m "message"  # Skip RuboCop only
git commit --no-verify -m "message"      # Skip all hooks
```

## Test Database Setup

Since there are no migrations, test database setup requires:
```bash
dropdb ned_test; createdb -O nsl ned_test; bundle exec rake db:schema:dump; bundle exec rake db:clean_up_structure_sql_ruby; RAILS_ENV=test bin/rails db:setup
```

The `structure.sql` may need hand-editing for complex views/extensions.

## Key Directories

```
app/
  controllers/     # CanCanCan authorization
  models/          # ActiveRecord models
    concerns/      # Shared model modules
    search/        # Search engine models
  services/        # BaseService pattern
config/
  history/         # Release notes (yearly YAML files)
  name-searches.yml  # Search directives
db/
  structure.sql    # Schema (externally managed)
spec/              # RSpec tests
test/              # Minitest tests
  factories/       # FactoryBot factories
  fixtures/        # Test fixtures
```

## Security Review (Oct 2026)

A security review was conducted in October 2026. The findings file (`tmp/review/findings.md`) is not in the repo, since `tmp/` is gitignored, so the finding numbers below refer to a document you may not have. Key items:

### What's in good shape
- Search DSL: all SQL fragments from whitelisted maps, user values always bound with `?`
- Raw SQL: all calls use constant strings or `sanitize_sql` with binds
- LDAP: filters use `Net::LDAP::Filter.eq` (escapes input)
- No `permit!` or `to_unsafe_h` anywhere

### Open items to address
- **Other `.html_safe` uses** (finding 3): wrap stored data in `sanitize(...)` rather than `.html_safe`. The review comment (NSL-5974) and the RHS detail displays (NSL-5980) are done. Many `.html_safe` calls remain across the views, most of them in the loader partials; NSL-5965 (in progress) continues the work
- **Transport hardening** (finding 4): `assume_ssl` is on (NSL-5973), and `force_ssl` too, with `/ping` excluded from the redirect (NSL-5966). The CSP runs in report-only mode, with violations logged by `ServicesController#csp_report` (NSL-5966); enforcing it is still to do. `config.hosts` remains commented out
- **Session handling** (finding 5): add `rate_limit` to sign-in. Sign-in deliberately does not call `reset_session`: sessions use the cookie store, so session fixation doesn't apply, and a reset broke deep links (see the comment in `sessions_controller.rb`). Revisit only if the session store moves server-side
- **API key in the query string** (finding 6, rest): Services URLs carry `?apiKey=`, which reaches Services and proxy access logs. Moving it to a header depends on what NSL Services supports
- **CI doesn't run RuboCop**: `lint-ruby.yml` runs only Brakeman, so the cops below are enforced only by the pre-commit hook. Adding a `bin/rubocop` step is pending a team decision

### Patterns to follow (from fixed findings)
- **Markdown** (finding 2, NSL-5964): `markdown_to_html` sanitizes. Never `.html_safe` Kramdown output
- **Stored HTML** (findings 3 and 11, NSL-5965/5979/5980): never `.html_safe` a database value. Use `sanitize_stored_html(...)` (`ApplicationHelper`) for values that hold NSL markup, such as `full_name_html`, `citation_html` and comments: it keeps the name and reference tags and strips scripts. Plain `sanitize(...)` is fine for other text. When building link text, sanitize the value and join it with icons using `safe_join`, rather than interpolating into a string and calling `.html_safe`
- **`detail_line` partial** (finding 11, NSL-5980): sanitizes `info` unless it's already safe, so pass a `safe_join` or `sanitize`d value, not `.html_safe` on stored data
- **JSON from services** (finding 10, NSL-5978): use `JSON.parse`, never `JSON.load`
- **Calls to Services** (finding 6, NSL-5987): use `ServicesHttp.get/post/put/delete` (same arguments as RestClient), never `RestClient` directly. It adds a 10s open timeout; pass `read_timeout:` only for calls that need a non-default one. Log Services URLs with `ServicesHttp.loggable(url)`, never the raw URL: it hides the API key

### Common bugs to avoid
- **Assignment in condition**: `=` instead of `==` (finding 8). Three bugs were fixed where `if x = y` was meant to be `if x == y`
- **Duplicate method definitions**: watch for methods defined twice (the second silently wins), including an `attr_*` plus a `def` of the same name
- **Unreachable code**: code after an unconditional `return`/`raise`, or after `throw` tripwires

### RuboCop lint cops (enabled in NSL-5978)
`.rubocop.yml` enables these on top of Omakase, and the repo has zero offences. Keep it that way:
- `Lint/AssignmentInCondition`
- `Lint/DuplicateMethods`
- `Lint/UnreachableCode`
- `Lint/InterpolationCheck`
- `Lint/UselessAssignment`
- `Security/JSONLoad`
