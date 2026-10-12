---
name: security-review
description: Review code for security vulnerabilities (SQL injection, XSS, authorization gaps, leaked secrets, unsafe service calls) and report findings grouped by severity. Use when the user asks for a security review of a file, a directory, or the changes on the current branch. Read-only - it reports issues and suggests fixes without applying them.
argument-hint: "[file-or-directory]"
allowed-tools: Read, Glob, Grep
---

# Security review

Review code for security vulnerabilities and report what you find, grouped by severity. This is a review only: suggest fixes, don't apply them.

## What to review

- With an argument (`$ARGUMENTS`): review that file or directory.
- With no argument: review the files changed on the current branch compared with `main` (`git diff main...HEAD --name-only`), plus any uncommitted changes.

Read each file in full, and follow the data: trace a value from where it enters (params, the database, a service response) to where it is used (SQL, a view, a log line, an outbound request). A finding needs that path, not just a suspicious-looking line.

Never open the files listed under "Sensitive Files - Do Not Read" in `CLAUDE.md`, even to check them. If a finding depends on what one contains, ask the developer.

## Project context

The "Security Review" section of `CLAUDE.md` records what the last review found, which patterns are the approved fixes, and which items are still open. Read it first:

- Use the approved patterns in your suggested fixes rather than inventing new ones.
- Don't re-report an open item as a new discovery. If the code under review touches one, say so and name the item.
- Don't report a decision that `CLAUDE.md` documents as deliberate (for example sign-in not calling `reset_session`) unless the reason given no longer holds.

## Review areas

### Injection

- **SQL**: queries are parameterized, with user values bound with `?` or passed through `sanitize_sql`. No interpolated params in `where`, `order`, `joins`, `select`, `find_by_sql`, or `execute`
- **Search DSL**: SQL fragments come from the whitelisted maps (`field_rule.rb`, `config/name-searches.yml`), never from the user's search string
- **LDAP**: filters are built with `Net::LDAP::Filter` helpers, not string concatenation
- **Commands and code**: no user input reaching `system`, backticks, `eval`, `send`, `constantize`, or `YAML.load`
- **JSON**: `JSON.parse`, never `JSON.load`

### XSS

- **Stored data**: never `.html_safe` or `raw` on a database value. NSL markup (`full_name_html`, `citation_html`, comments) goes through `sanitize_stored_html(...)`; other text through `sanitize(...)`
- **Markdown**: rendered with `markdown_to_html`, never `.html_safe` on Kramdown output
- **Building HTML**: `safe_join` and tag helpers, not string interpolation followed by `.html_safe`
- **JavaScript**: values written into inline scripts, `data-` attributes, and JS responses (`.js.erb`) are escaped (`j`, `to_json`)

### Authentication and authorization

- **New actions**: every new controller action is covered by a CanCanCan ability, and the test suite covers the denied case as well as the allowed one
- **Object access**: records are loaded in a way that respects the user's permissions, not just by an `id` from params
- **Strong parameters**: explicit `permit` lists. No `permit!` or `to_unsafe_h`, and no role or ownership fields in a permit list
- **CSRF**: no `skip_forgery_protection` or `protect_from_forgery` exceptions without a stated reason
- **Sessions**: nothing sensitive stored in the session, since it is a client-side cookie

### Sensitive data

- **Secrets**: no hardcoded credentials, API keys, or tokens, and none committed in config
- **Logs**: no secrets or personal data in log lines or error messages, including URLs that carry `apiKey=`
- **Parameter filtering**: new sensitive params are added to the filter list
- **Errors**: no stack traces or internal detail shown to the user

### Outbound service calls

- **Timeouts**: RestClient calls to NSL Services and the Mapper set explicit timeouts
- **Credentials**: API keys go in a header rather than the query string
- **URLs**: no user-controlled host or path in an outbound request (SSRF), and no open redirects from `redirect_to params[...]`
- **Failure handling**: the service being down or returning something unexpected is handled, and the response is not trusted as safe HTML

### Other

- **File handling**: uploads and downloads (loader batches, exports) validate type and size, and never build a path from user input
- **Mass operations**: bulk updates and deletes are scoped and authorized
- **Dependencies**: a new or upgraded gem has no known advisory (`bundle exec bundle-audit`)
- **Configuration**: no weakening of `force_ssl`/`assume_ssl`, cookie flags, or host and CSP settings

## Output format

Leave out a severity heading if it has no findings, and don't pad the review with findings you aren't confident in. Say which ones you verified by tracing the data and which are worth a second look.

```
### Critical
Exploitable now: injection, authorization bypass, leaked secrets

### High
Exploitable with some precondition, or a missing control on a sensitive path

### Medium
Weakens a defence without a direct exploit

### Low
Hardening suggestions

### Checked and fine
Areas you examined and found sound
```

For each issue, give:

- **Location**: file and line number, as `path/to/file.rb:42`
- **Issue**: what the vulnerability is, with the offending snippet
- **Impact**: what an attacker could do, and who could do it (anonymous, any signed-in user, a specific role)
- **Solution**: a specific code example of the fix, using this repo's approved patterns

Finish by suggesting `bin/brakeman` (run in the app container) if the review covered more than a couple of files, since it catches patterns a manual read can miss.
