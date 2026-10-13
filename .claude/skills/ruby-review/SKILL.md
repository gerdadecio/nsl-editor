---
name: ruby-review
description: Review Ruby code for best practices, security, performance, and maintainability, and report findings grouped by severity. Use when the user asks for a Ruby code review of a file, a directory, or the changes on the current branch. Read-only - it reports issues and suggests fixes without applying them.
argument-hint: "[file-or-directory]"
allowed-tools: Read, Glob, Grep
---

# Ruby code review

Review Ruby code and report what you find, grouped by severity. This is a review only: suggest fixes, don't apply them.

## What to review

- With an argument (`$ARGUMENTS`): review that file or directory.
- With no argument: review the Ruby files changed on the current branch compared with `main` (`git diff main...HEAD --name-only`), plus any uncommitted changes.

Read each file in full before commenting on it, and read enough of the surrounding code (callers, the concern or service it uses, its tests) to judge it in context.

## Project conventions come first

`CLAUDE.md` describes how this repo works. Where it disagrees with the general guidance below, `CLAUDE.md` wins. In particular:

- RuboCop (Omakase plus the project cops in `.rubocop.yml`) defines the style. Line and method length limits are disabled, so don't report length on its own. Report a long method only when it hides a real design problem.
- The schema is managed externally through `structure.sql`, with no migrations. Raise a missing index as a note for whoever owns the schema, not as a migration to write.
- Stored HTML goes through `sanitize_stored_html(...)` or `sanitize(...)`, never `.html_safe`.
- Business logic belongs in service objects (`BaseService`), with shared model behavior in concerns.
- Check the "After Every Change" list and the "Common bugs to avoid" section of `CLAUDE.md` against the code.

## Review areas

### Code quality and design

- **Style**: follows the Ruby community style guide and this repo's RuboCop config
- **Naming**: snake_case for variables and methods, PascalCase for classes and modules, and names that say what the thing is for
- **Responsibilities**: classes follow the Single Responsibility Principle, with low coupling and high cohesion
- **SOLID and DRY**: no obvious violations; duplicated code is pointed out with a refactoring suggestion
- **Dependencies**: inverted where that makes the code easier to test or more flexible
- **Iceberg classes**: no small public interface sitting on a large private footprint
- **Unbounded growth**: adding a feature or command shouldn't make a class's public interface grow without limit
- **Extensibility**: adding a feature or extending behavior doesn't take a lot of effort
- **Resilience to change**: a change in the format of the input or the output doesn't ripple through the code
- **Edge cases**: unusual inputs don't break the application
- **Large inputs**: a large amount of data doesn't kill the application or make it unresponsive
- **Tooling and layout**: idiomatic project layout, sensible use of source control and Docker, minimal global namespace pollution

### Security

- **SQL injection**: ActiveRecord queries are parameterized, with no interpolated user input
- **XSS**: views and templates escape or sanitize user and stored data
- **Authentication and authorization**: the logic is sound, and new actions are covered by CanCanCan abilities
- **Sensitive data**: no hardcoded secrets, API keys, or passwords, and none in logs
- **Input validation**: user input is validated
- **File uploads**: uploads are handled safely

### Performance

- **N+1 queries**: associations used in loops and views are loaded with `includes`/`preload`
- **Memory**: no leaks or wasteful object creation (for example `each` over a large AR collection instead of `find_each`)
- **Caching**: suggest it where it would clearly help
- **Algorithmic complexity**: loops and data processing are efficient
- **Indexes**: query patterns that look like they need an index the schema doesn't have

### Best practices

- **Error handling**: exceptions are handled and logged properly, and the handling is actually exercised (no stack traces reaching the user)
- **Testing**: coverage and quality, with a sensible mix of unit and integration tests
- **Documentation**: comments and docs where the code needs them
- **Gem dependencies**: appropriate use, with no known vulnerabilities
- **Configuration**: environment-specific settings are in the right place
- **Code organization**: files and directories follow the repo's structure

### Ruby-specific patterns

- **Blocks, procs, and lambdas**: the right callable for the job
- **Metaprogramming**: used where it earns its keep, without hidden pitfalls
- **Modules and classes**: mixins and inheritance used appropriately
- **Constants**: defined and used properly
- **Strings**: efficient handling and interpolation

### Thought process

- Assumptions and design decisions that are called out and address one of the areas above
- Interesting or innovative elements that the areas above don't cover

## Output format

Prioritize security vulnerabilities, then performance-critical issues. Leave out a severity heading if it has no findings, and don't pad the review with findings you aren't confident in.

```
### Critical Issues
Security vulnerabilities requiring immediate attention

### High Priority
Performance problems and major code quality issues

### Medium Priority
Style violations and minor refactoring opportunities

### Low Priority
Suggestions for improvement and optimization

### Positive Observations
Well-implemented patterns and good practices found
```

For each issue, give:

- **Location**: file and line number, as `path/to/file.rb:42`
- **Issue**: a clear description of the problem, with the offending snippet
- **Impact**: why it matters
- **Solution**: a specific code example of the fix, using Ruby idioms and this repo's patterns

Keep the feedback constructive and educational.
