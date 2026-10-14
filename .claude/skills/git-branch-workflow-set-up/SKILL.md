---
name: git-branch-workflow-set-up
description: Make a change the way this repo expects - create a local branch and commit, then hand back to the developer, who reviews, pushes to their fork (origin), and raises the PR to upstream. Use when starting or shipping a change, or when the user asks to branch or commit.
argument-hint: "[jira-id or branch-name]"
---

# Git branch workflow

This repo is a fork. Changes go to `upstream` (`bio-org-au/nsl-editor`) through a PR from a branch on your fork (`origin`). Never commit directly to `main`.

## 1. Create a local branch

- Start from an up-to-date `main`. If it's behind `upstream/main`, run `/post-merge-clean-up` or `git fetch upstream && git merge upstream/main` first.
- Branch names:
  - With a Jira ticket: `nsl-<number>`, lowercase, for example `nsl-5974`.
  - Without one: a short kebab-case description, for example `update-claude-md-git-workflow`.
- `git checkout -b <branch-name>`. Uncommitted work comes with you onto the new branch.
- **Branch from local `main`, never from a remote branch.** `git checkout -b <branch-name> upstream/main` makes the new branch track `upstream/main`, so a plain `git push` then targets the upstream repo's `main`. Git refuses it ("The upstream branch of your current branch does not match the name of your current branch"), and the commands git suggests in that message both push to upstream. To start from the latest upstream, update local `main` first (above). If you really need to branch from `upstream/main`, add `--no-track`. Check with `git branch -vv`: a new branch should show no tracking branch until it's pushed with `git push -u origin <branch-name>`.

## 2. Commit

- Ask the user whether this change should be recorded in the change history. If it should, run `/change-history-and-version` before committing. Changes that don't affect users (tooling, docs, CLAUDE.md, skills) usually skip it.
- Stage the files explicitly. Don't use `git add -A`, because it can pick up stray files.
- Commit message format:
  - With a Jira ticket: `NSL-<number>: <Area>: <description>`, matching the history entry, for example `NSL-5974: Security: Sanitize Batch Loader Review Comment HTML`.
  - Without one: a short imperative summary, for example `Add CLAUDE.md for Claude Code guidance`.
- The pre-commit hook runs RuboCop on staged Ruby files and blocks Bootstrap 3/4 classes. If it fails, fix the problem. Don't bypass it with `--no-verify` unless the user asks.

## 3. Stop and hand back to the developer

**Don't push, and don't create the PR.** The developer reviews the commit first, then does both steps themselves. Creating a PR on GitHub means filling in `.github/PULL_REQUEST_TEMPLATE.md`, and the developer answers those questions.

Hand back with:
- the branch name and the commit (`git log --oneline -1 --stat`)
- the commands for the remaining steps, ready to copy:
  ```bash
  git push -u origin <branch-name>
  ```
  then create the PR on GitHub to `bio-org-au/nsl-editor` `main`, filling in the PR template.

Push only if the developer explicitly asks you to in this conversation. Even then, leave the PR to them unless they say otherwise.

After the PR is merged, run `/post-merge-clean-up`.
