---
name: changelog
description: This skill should be used when the user asks to "update the changelog", "add changelog entries", "what changed since last release", or when updating CHANGELOG.md with user-facing changes. Follows Keep a Changelog format and filters out internal-only commits.
---

# Update CHANGELOG.md

Update a project's CHANGELOG.md with relevant user-facing changes since the
last versioned release.

## Iron Laws

- **ONLY USER-FACING CHANGES** — internal refactors, CI config, test-only changes, and release bookkeeping do not belong in the changelog
- **NEVER DUPLICATE** — check the existing `[Unreleased]` section before adding entries
- **DESCRIBE IMPACT, NOT IMPLEMENTATION** — write what changed for the user, not what the commit did

## Procedure

### 1. Find the baseline

Read `CHANGELOG.md` and identify the most recent **versioned** release heading
(e.g., `## [0.5.1] - 2026-02-27`). Extract the version tag (e.g., `v0.5.1`).

### 2. Gather commits since baseline

```bash
git log --oneline <tag>..HEAD
```

If the tag doesn't exist as a git tag, fall back to finding the commit whose
message contains the version string (e.g., `chore(release): 0.5.1`) and use
that commit hash instead.

### 3. Classify each commit

For every commit, read the diff (`git show --stat <hash>` and `git show <hash>`
as needed) and classify it:

- **User-facing** — changes to commands, features, APIs, configuration,
  workflow behavior, or documentation that affects how users interact with the
  project.
- **Internal-only** — CI config, test-only changes, refactors with no behavior
  change, changelog-only updates, release bookkeeping.

**Skip internal-only commits.** Only user-facing changes belong in the
changelog.

Also skip any commit already represented in the existing `[Unreleased]` section.

### 4. Write changelog entries

Group changes under [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
categories:

- **Added** — new features, commands, capabilities
- **Changed** — modifications to existing behavior
- **Deprecated** — soon-to-be-removed features
- **Removed** — removed features
- **Fixed** — bug fixes
- **Security** — vulnerability fixes

Only include categories that have entries. Place entries under the
`## [Unreleased]` heading, preserving any existing unreleased entries that are
still accurate.

Each entry should be a concise, user-oriented description of **what changed and
why it matters**, not a restatement of the commit message.

### 5. Report

If there are no user-facing changes to add, say so and do not modify the file.

If changes were added, show the user what was written to the `[Unreleased]`
section.
