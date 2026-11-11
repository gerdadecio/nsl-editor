---
name: change-history-and-version
description: Record a user-facing change in the change history by adding a pending entry file (config/history/pending/NSL-<id>.yml). The version bump and the move into config/history/changes-YYYY.yml happen automatically after merge. Also covers noting a release and setting up a new year. Use for changes that affect users of the Editor, usually ones with a Jira ticket. Skip it for tooling, docs, or Claude config changes.
argument-hint: "[jira-id] [description]"
---

# Change history and version

Users can see changes that affect them on the in-app History page (`/history/<year>`). Each change of this kind also bumps the app version.

**PRs don't edit `config/history/changes-<year>.yml` or `config/version.properties`.** Every PR used to edit both, so open PRs always conflicted with each other. Now:

1. The PR adds its own file, `config/history/pending/NSL-<id>.yml`.
2. After the PR merges to upstream `main`, the `fold-history-and-bump-version` workflow moves the entry to the top of `changes-<year>.yml` (`bin/fold-history`), deletes the pending file, bumps the last number of `appversion` (`bin/bump-version`), and commits `Changelog and version X.Y.Z.N`.

The History page shows pending entries too, so the change is visible locally before merge.

## When to use it

- **Use it** for changes users would notice: bug fixes, features, and security fixes. These usually have a Jira ticket.
- **Skip it** for changes that don't affect users, such as CLAUDE.md, skills, editor config, or CI tooling. If you're unsure, ask the user. A merge with no pending file doesn't bump the version.

## 1. Add the pending entry

Create `config/history/pending/NSL-<jira_id>.yml`. It holds one list entry, in exactly the form it will take in the yearly file:

```yaml
- :date: 08-October-2026
  :jira_id: '5974'
  :description: |-
    Security: Sanitize Batch Loader Review Comment HTML
```

- The file must start with `- :date:`. The text is copied into the yearly file as is.
- `:date:` uses the `DD-Month-YYYY` format with the month written in full, using today's date. The year decides which `changes-<year>.yml` the entry goes into.
- `:jira_id:` is the ticket number only, as a **quoted string**, without the `NSL-` prefix.
- `:description:` is `<Area>: <what changed>`, in plain words for users, for example `Loader Batch: Fix bug in ...` or `Typeahead upgrade: ...`. Ask the user for the Jira number and wording if you don't have them.
- `test/lib/change_history_test.rb` checks every pending file, so run it (or the full suite) before pushing.

Don't touch `config/version.properties` in a normal PR (see "Minor and major versions" below for the exception).

## 2. Commit

Include the pending file in the same commit as the change itself. The commit subject matches the entry: `NSL-<jira_id>: <description>`.

## Noting a release

A release merges a chosen commit on `main`, not necessarily the latest, into the `release` branch.

- **Release the bot's `Changelog and version …` commit** that follows the PR merge, not the PR's merge commit. Otherwise the build shows the previous version number.
- Then, on an up-to-date `main` (or a branch from it), note the release in the history:
  ```
  bin/note-release <released-commit> <version> [DD-Month-YYYY]
  ```
  This puts the release marker directly above the newest entry that was in the released commit, so entries above the marker came after the release. It refuses if there are unfolded pending files, if the release is already noted, or if it can't find the released entries.
- Set the next version with `bin/bump-version release` (for example `5.1.8.44` → `5.1.9.00`), and commit both files.

## Minor and major versions

The workflow only ever bumps the last number. For anything bigger, run one of these and commit `config/version.properties`:

```
bin/bump-version release   5.1.8.33 -> 5.1.9.00
bin/bump-version minor     5.1.8.33 -> 5.2.0.00
bin/bump-version major     5.1.8.33 -> 6.0.0.00
```

The numbers after the bumped one reset to zero, and each keeps its padding. If a PR sets the version like this *and* adds a pending changelog entry, the workflow still moves the entry but doesn't bump, so the version stays exactly what the PR set. The next merge bumps from there (`5.2.0.00` → `5.2.0.01`).

## First change of a new year

The History page for a year needs more than its entries:
- an empty `config/history/changes-<year>.yml`. `bin/fold-history` also creates it if it's missing.
- an `app/views/history/_<year>.html.erb` partial (copy last year's and change the year),
- the year added to the `history/:year` route constraint in `config/routes.rb`,
- a "Changes <year>" link at the top of the year links in `app/views/layouts/_help_menu.html.erb`.

Look at the previous year's setup commit for the pattern (`git log --diff-filter=A -- config/history/changes-<last year>.yml`). The first entry is traditionally `History: Set up Changes <year> page`.
