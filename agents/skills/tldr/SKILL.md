---
name: tldr
description: 'This skill should be used when the user asks to look up command usage, check how to use a CLI tool, find practical examples for a command, or when an AI agent needs to quickly understand an unfamiliar shell command. Trigger phrases: "how do I use X", "show me examples for X", "look up X", "tldr X", "man X", "what flags does X have", "how does X work", "quick reference for X", "check the docs for X".'
---

# tldr — Simplified Command Reference

`tldr` shows practical, community-curated examples for shell commands.
Installed at `/opt/homebrew/bin/tldr`.

## User Alias

The user has configured:

```sh
alias man="tldr"
```

Invoking `man <command>` already calls `tldr`. Use `tldr` directly (not
`man`) in scripts and agent contexts to be explicit.

## When to Use tldr vs man

- Use `tldr` to quickly learn common usage patterns and flags for a command.
- `tldr` is the right first stop — it shows curated examples, not full docs.
- Fall back to `man` (the real man) or `--help` only when tldr lacks a page
  or you need exhaustive detail (e.g., obscure flags, POSIX compliance notes).

## Core Usage Patterns

### Look up a command

```sh
tldr ls
tldr git
tldr curl
tldr tar
```

### Look up a command for a specific platform

```sh
tldr -p osx open          # macOS-specific examples
tldr -p linux chmod       # Linux-specific examples
tldr -p windows ping      # Windows-specific examples
tldr -p common grep       # Platform-agnostic examples
tldr -p sunos df          # Solaris/illumos examples
```

Use `-p` when the default platform gives irrelevant results, or when
cross-platform differences matter for the task at hand.

### List all available pages

```sh
tldr -l
tldr --list
```

Pipe through `grep` to check whether a page exists before looking it up:

```sh
tldr -l | grep ffmpeg
```

### Update the local database

```sh
tldr -u
tldr --update
```

Run this when pages are missing or outdated. The database lives at
`~/.tldr/cache/` (or `$XDG_CACHE_HOME/tldr/`).

### Render a local page for testing

```sh
tldr -r path/to/page.md
tldr --render path/to/page.md
```

Use `-r` when authoring or previewing a custom tldr page locally.

## Key Flags Reference

| Flag | Long form | Description |
|------|-----------|-------------|
| `-p PLATFORM` | `--platform` | Select platform: `linux`, `osx`, `sunos`, `windows`, `common` |
| `-l` | `--list` | List all pages in the local database |
| `-u` | `--update` | Update the local page database |
| `-r PATH` | `--render` | Render a local markdown file as a tldr page |
| `-C` | `--color` | Force color output even when piping |
| `-V` | `--verbose` | Verbose output (useful with `-u` or `-c`) |
| `-c` | `--clear-cache` | Delete the local database |
| `-v` | `--version` | Print version and exit |
| `-h` | `--help` | Print help and exit |

## Auto-Update Behavior

`tldr` may auto-update its local database on first run or when the cache is
stale. To disable auto-updates (e.g., in offline or CI environments):

```sh
export TLDR_AUTO_UPDATE_DISABLED=1
tldr ls
```

## Common Scenarios

### Learn a command before using it

```sh
tldr rsync        # understand key flags before running a sync
tldr awk          # recall common awk one-liners
tldr jq           # find the right jq filter syntax
```

### Check platform-specific behavior

```sh
tldr -p osx brew          # Homebrew usage on macOS
tldr -p linux apt         # apt usage on Debian/Ubuntu
```

### Verify a page exists before scripting

```sh
tldr -l | grep -q "^fd$" && echo "page available" || echo "no page"
```

### Force color when piping output

```sh
tldr -C fd | less -R
```

## Tips for Agent Use

- Call `tldr <command>` before running an unfamiliar command to quickly
  confirm correct syntax and avoid mistakes.
- Prefer `tldr` over `--help` for human-readable output; prefer `--help`
  when you need every flag listed exhaustively.
- Use `-p osx` on macOS when the default page shows Linux-specific flags
  that differ (e.g., `sed`, `find`, `date`).
- When a page is missing, run `tldr -u` once to refresh the database, then
  retry.
- Set `TLDR_AUTO_UPDATE_DISABLED=1` in automated scripts to prevent
  unexpected network calls mid-execution.
- `tldr -l | grep <term>` is faster than guessing page names for tools with
  multiple subcommand pages (e.g., `git-commit`, `git-rebase`).
