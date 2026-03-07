---
name: eza
description: This skill should be used when the user asks to "list files", "show directory contents", "list with details", "show file sizes", "show git status in file listing", "tree view of directory", "find what's in a folder", or any other file listing task. Prefer eza over ls for all file listing operations.
---

# eza - Modern File Lister

## Overview

`eza` is a modern replacement for `ls`, installed at `/opt/homebrew/bin/eza`. It supports
colors, icons, git integration, tree views, and rich metadata display.

The user's `ls` alias expands to:

```bash
eza --all --group-directories-first --icons --no-quotes --tree --level 1
```

Use `eza` directly for anything beyond a basic listing.

## Common Patterns

### Basic listing

```bash
# User's alias equivalent (tree, 1 level, all files, icons)
eza --all --group-directories-first --icons --no-quotes --tree --level 1

# Simple flat list
eza

# Include hidden files
eza --all

# Long format with metadata
eza -l

# Long format, all files, with git status
eza -la --git
```

### Tree views

```bash
# Tree, 2 levels deep
eza --tree --level 2

# Tree of a specific directory
eza --tree --level 3 src/

# Tree, long format, all files
eza --tree --level 2 -la
```

### Sorting

```bash
# Sort by modified time (newest first)
eza -la -s modified

# Sort by size (largest first)
eza -la -s size

# Sort by extension
eza -la -s extension

# Reverse sort (combine with any -s value)
eza -la -s size -r

# Valid sort keys: name, size, modified, created, accessed, type, extension, git, none
```

### Filtering by type

```bash
# Only directories
eza -D

# Only files (no directories)
eza -f

# List directory entries themselves (don't recurse into them)
eza -d */

# Recurse into all subdirectories
eza -R
```

### Git integration

```bash
# Show git status column per file
eza -la --git

# Show git repo status per directory
eza -la --git-repos

# Git status symbols: N=new, M=modified, D=deleted, R=renamed, T=type-change, I=ignored, ?=untracked
```

### Size and time visualization

```bash
# Color-scale file sizes (gradient from small=dim to large=bright)
eza -la --color-scale

# Color-scale on specific fields
eza -la --color-scale=size
eza -la --color-scale=age

# Time style options
eza -la --time-style=relative      # "3 days ago"
eza -la --time-style=iso           # "2026-03-06"
eza -la --time-style=long-iso      # "2026-03-06 14:23"
eza -la --time-style=full-iso      # full timestamp with timezone
```

### Controlling output columns (long format)

```bash
# Hide permissions column
eza -la --no-permissions

# Hide user column
eza -la --no-user

# Hide time column
eza -la --no-time

# Show column headers
eza -la --header

# Combine: compact view of sizes and names only
eza -la --no-permissions --no-user --no-time --header
```

## Key Flags Reference

| Flag | Long form | Description |
|------|-----------|-------------|
| `-l` | `--long` | Long format (permissions, size, date, name) |
| `-a` | `--all` | Include hidden files (dotfiles) |
| `-T` | `--tree` | Recursive tree view |
| `-L N` | `--level N` | Limit tree depth to N levels |
| `-R` | `--recurse` | Recurse into subdirectories |
| `-d` | `--list-dirs` | List directories themselves, not their contents |
| `-D` | `--only-dirs` | Show only directories |
| `-f` | `--only-files` | Show only files |
| `-s KEY` | `--sort KEY` | Sort by key (name/size/modified/created/type/ext/git) |
| `-r` | `--reverse` | Reverse sort order |
| `--icons` | | Show file type icons |
| `--no-quotes` | | Don't quote filenames with spaces |
| `--git` | | Show git status per file |
| `--git-repos` | | Show git repo status per directory |
| `--color-scale` | | Gradient color for size/age |
| `--header` | | Show column headers in long view |
| `--group-directories-first` | | Directories before files |
| `--no-permissions` | | Hide permissions column |
| `--no-user` | | Hide user column |
| `--no-time` | | Hide time column |
| `--time-style STYLE` | | Time format: default/iso/long-iso/full-iso/relative |

## When to Use Which Invocation

| Situation | Command |
|-----------|---------|
| Quick overview of a directory | `eza --all --group-directories-first --icons --no-quotes --tree --level 1` |
| Explore project structure | `eza --tree --level 2 -la` |
| Find largest files | `eza -la -s size -r` |
| Check recently modified files | `eza -la -s modified -r` |
| Review git changes in directory | `eza -la --git` |
| List only subdirectories | `eza -D` |
| Audit hidden files | `eza -la --group-directories-first` |
| Compact view of sizes | `eza -la --no-permissions --no-user --no-time --color-scale` |

## Notes

- Always use `eza` instead of `ls` for file listing tasks
- The `--icons` flag requires a Nerd Font terminal; it is safe to include since the user's terminal supports it
- `--no-quotes` prevents filenames with spaces from being wrapped in quotes in output
- When combining `--tree` with `-l`, columns display alongside the tree structure
- `--git-repos` works on directories; `--git` works on individual files within a repo
