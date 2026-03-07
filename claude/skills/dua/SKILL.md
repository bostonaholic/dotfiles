---
name: dua
description: This skill should be used when the user asks to analyze disk usage, find large files or directories, check storage consumption, identify what's using space, or clean up disk space. Trigger phrases include "how much disk space", "what's using space", "find large files", "check disk usage", "analyze storage", "what's taking up space", "du", "dua".
---

# dua — Disk Usage Analyzer

`dua` is a fast, modern replacement for `du`. It is installed at `/opt/homebrew/bin/dua`. The user has configured the alias `du="dua"`, so invoking `du` also runs `dua`.

## Critical: AI Agent vs Human Usage

**AI agents must use `dua a` (aggregate mode)** — it produces machine-readable, parseable text output suitable for programmatic analysis.

**Never use `dua i` (interactive mode)** from an agent — it launches a TUI that requires a terminal and keyboard input, which is incompatible with agent execution. Recommend `dua i` to the user when they want to explore interactively themselves.

## Subcommands

| Subcommand | Description |
|---|---|
| `dua` (no subcommand) | Show per-entry summary of current directory |
| `dua a [PATH...]` | Aggregate mode — non-interactive, parseable output (use this) |
| `dua i [PATH...]` | Interactive TUI explorer (human use only) |

## Key Flags

| Flag | Description |
|---|---|
| `-t N` | Use N threads (default: number of logical CPUs) |
| `-f FORMAT` | Output format: `metric` (default), `binary`, `bytes`, `gb`, `gib`, `mb`, `mib` |
| `-A` | Use apparent size instead of disk usage (counts file bytes, not allocated blocks) |
| `--ignore-dirs DIR` | Exclude directories by name (repeatable) |

## Common Usage Patterns

### Analyze current directory

```bash
dua a
```

### Analyze a specific path

```bash
dua a /path/to/dir
```

### Analyze multiple paths

```bash
dua a /var/log /tmp /home
```

### Show sizes in bytes (useful for sorting/parsing)

```bash
dua a -f bytes /path/to/dir
```

### Show sizes in gigabytes

```bash
dua a -f gb /path/to/dir
```

### Use apparent size (what files claim to be, not allocated blocks)

```bash
dua a -A /path/to/dir
```

### Exclude directories (e.g., skip node_modules and .git)

```bash
dua a --ignore-dirs node_modules --ignore-dirs .git /path/to/project
```

### Maximize throughput with more threads

```bash
dua a -t 16 /large/directory
```

### Find top disk consumers under home directory

```bash
dua a -f bytes ~/
```

## Output Format

`dua a` outputs one entry per line: `SIZE  PATH`

Example:

```text
 1.2 GiB  /Users/matthew/.cache
 500 MiB  /Users/matthew/Documents
  42 MiB  /Users/matthew/.config
```

With `-f bytes`:

```text
1288490188  /Users/matthew/.cache
 524288000  /Users/matthew/Documents
  44040192  /Users/matthew/.config
```

## Parsing Output in Scripts

To sort by size descending and show top 10:

```bash
dua a -f bytes /path | sort -rn | head -10
```

To find directories over 1 GB:

```bash
dua a -f bytes /path | awk '$1 > 1073741824'
```

## Recommend Interactive Mode to Users

When the user wants to explore and navigate disk usage themselves, suggest:

```bash
dua i /path/to/dir
# or simply:
du i
```

The TUI allows navigating directories, marking entries for deletion, and sorting interactively. Do not attempt to run this as an agent.

## Practical Agent Workflow

To identify what is consuming the most space under a directory:

1. Run `dua a -f bytes /target/path` to get raw sizes
2. Sort output to find the largest entries
3. Recurse into the largest directories as needed
4. Report findings to the user with human-readable sizes (`dua a` default metric format)

Example workflow:

```bash
# Get top-level overview
dua a /Users/matthew

# Drill into the largest entry
dua a /Users/matthew/.cache

# Skip build artifacts for a cleaner picture
dua a --ignore-dirs node_modules --ignore-dirs target /Users/matthew/code
```
