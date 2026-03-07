---
name: fd
description: This skill should be used when the user asks to find files, search for files by name or type, locate files matching a pattern, or perform any file system search. Trigger phrases include "find files", "search for files", "locate files named", "find all .js files", "find files modified recently", "find directories", "find files larger than", "find and delete files", "find and execute command on files".
---

# fd — Fast File Finder

## Overview

`fd` is a fast, ergonomic alternative to `find`. It uses regex patterns by default, respects `.gitignore` by default, and has colorized output with smart case matching.

**Binary:** `/opt/homebrew/bin/fd`
**User alias:** `find="fd"` — the user types `find` but it runs `fd`.

## Core Syntax

```bash
fd [OPTIONS] [pattern] [path]
```

- Pattern is **regex by default** (not glob)
- Path defaults to current directory if omitted
- Smart case: case-insensitive unless pattern contains uppercase

## Key Flags

| Flag | Long form | Purpose |
|------|-----------|---------|
| `-g` | `--glob` | Glob pattern instead of regex |
| `-H` | `--hidden` | Include hidden files/dirs (dotfiles) |
| `-I` | `--no-ignore` | Ignore `.gitignore`/`.fdignore` rules |
| `-u` | `--unrestricted` | Shorthand for `-H -I` (search everything) |
| `-e ext` | `--extension` | Filter by file extension |
| `-t type` | `--type` | Filter by entry type |
| `-d N` | `--max-depth` | Limit traversal depth |
| `-E pat` | `--exclude` | Exclude matching paths |
| `-S size` | `--size` | Filter by file size |
| `-x cmd` | `--exec` | Execute command per result |
| `-X cmd` | `--exec-batch` | Execute command once with all results |
| `-0` | `--print0` | Null-separate output (for `xargs -0`) |
| `-a` | `--absolute-path` | Print absolute paths |
| `-l` | `--list-details` | Long listing format (like `ls -l`) |
| `-1` | | Limit to single result |
| `-q` | `--quiet` | Exit code only (0=match, 1=no match) |

## Type Filters (`-t`)

| Value | Matches |
|-------|---------|
| `f` | Regular files |
| `d` | Directories |
| `l` | Symlinks |
| `x` | Executables |
| `e` | Empty files/dirs |
| `p` | Named pipes |
| `s` | Sockets |
| `b` | Block devices |
| `c` | Character devices |

## Common Patterns

### Basic file search

```bash
# Find files matching a regex pattern
fd config

# Find files with exact name (use glob for literal match)
fd -g 'config.json'

# Find in a specific directory
fd pattern /path/to/search

# Find files with extension
fd -e js
fd -e ts -e tsx

# Find directories only
fd -t d node_modules

# Find hidden files too
fd -H '\.env'

# Search everything (hidden + ignored)
fd -u pattern
```

### Type and extension filtering

```bash
# Find all Python files
fd -e py

# Find executable scripts
fd -t x

# Find empty directories
fd -t d -t e

# Find symlinks
fd -t l
```

### Depth control

```bash
# Only top-level files
fd -d 1

# Maximum two levels deep
fd -d 2 -t f
```

### Excluding paths

```bash
# Exclude node_modules
fd -E node_modules pattern

# Exclude multiple patterns
fd -E '*.log' -E 'dist' -E 'build' pattern

# Combine with hidden/no-ignore
fd -H -I -E '.git' pattern
```

### Size filtering

```bash
# Files larger than 1MB
fd -S +1M -t f

# Files smaller than 10KB
fd -S -10k -t f

# Files between 1MB and 100MB
fd -S +1M -S -100M -t f
```

### Time-based filtering

```bash
# Modified within the last day
fd --changed-within 1d

# Modified within the last 2 weeks
fd --changed-within 2weeks

# Modified before a date
fd --changed-before 2024-01-01

# Recently modified JavaScript files
fd -e js --changed-within 1h
```

### Execution

```bash
# Execute command per result (-x runs in parallel)
fd -e log -x rm {}

# Execute once with all results as arguments (-X is batch)
fd -e js -X wc -l

# Sequential execution (one at a time)
fd pattern -x --threads=1 process_file {}

# Pipe-safe: null-separate output for xargs
fd -0 pattern | xargs -0 command
```

**Placeholders for `-x` / `-X`:**

| Placeholder | Value |
|-------------|-------|
| `{}` | Full path |
| `{/}` | Filename only |
| `{//}` | Parent directory |
| `{.}` | Path without extension |
| `{/.}` | Filename without extension |

### Absolute paths and listing

```bash
# Print absolute paths
fd -a pattern

# Long listing format
fd -l -e md

# Single result (first match)
fd -1 README
```

## fd vs. find Equivalents

| Goal | fd | find |
|------|----|------|
| Find by name | `fd filename` | `find . -name filename` |
| Find by extension | `fd -e js` | `find . -name '*.js'` |
| Find directories | `fd -t d name` | `find . -type d -name name` |
| Include hidden | `fd -H pattern` | `find . -name '*.swp'` |
| Exec per result | `fd pat -x cmd {}` | `find . -name pat -exec cmd {} \;` |
| Exec batch | `fd pat -X cmd` | `find . -name pat -exec cmd {} +` |
| Max depth | `fd -d 2 pat` | `find . -maxdepth 2 -name pat` |
| Exclude dir | `fd -E dir pat` | `find . -not -path '*/dir/*'` |
| Newer than | `fd --changed-within 1d` | `find . -newer ref_file` |
| Larger than | `fd -S +1M` | `find . -size +1M` |
| Null output | `fd -0 pat` | `find . -name pat -print0` |

## Practical Workflows

### Clean build artifacts

```bash
fd -t d -E .git '(dist|build|__pycache__|\.cache)' -X rm -rf
```

### Find and replace in files

```bash
# Find all TypeScript files, then run sed on them
fd -e ts -X sed -i 's/oldName/newName/g'
```

### Find large files to investigate

```bash
fd -S +10M -t f -l | sort -k5 -h
```

### Find recently changed config files

```bash
fd -e json -e yaml -e toml --changed-within 1h
```

### Check if a file exists (scripting)

```bash
if fd -q -g 'package.json' -d 1; then
  echo "Node project detected"
fi
```

### Find duplicate-looking log files

```bash
fd -e log --changed-before 7d -x rm {}
```

## Integration Notes

- **Respects `.gitignore` by default** — use `-I` when searching outside git repos or when you need ignored files
- **Smart case** — `fd Foo` is case-sensitive, `fd foo` is case-insensitive
- **Color output** — automatically disabled when piping; always-on with `--color=always`
- **Parallel exec** — `-x` runs commands in parallel by default; add `--threads=1` for sequential
- **`-X` vs `-x`** — use `-X` when the command accepts multiple arguments (e.g., `wc -l`, `rm`); use `-x` when you need per-file processing with placeholders
