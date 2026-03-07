---
name: ripgrep
description: This skill should be used when the user asks to "search for code", "find files containing X", "grep for a pattern", "search across the codebase", "find all usages of X", or any task requiring recursive text or pattern search. Prefer rg over grep for all searches.
---

# ripgrep (rg)

## Overview

`rg` is the default grep on this system (`grep="rg"`). It is faster than grep, respects `.gitignore` by default, and uses regex syntax. Installed at `/opt/homebrew/bin/rg` (v15.1.0).

**Default behavior:** recursive from current directory, regex patterns, respects `.gitignore` and `.rgignore`, skips hidden files and binary files.

## Core Flags

### Pattern Matching

| Flag | Meaning |
|------|---------|
| `-i` | Case insensitive |
| `-s` | Case sensitive (override smart-case) |
| `-S` | Smart case: case-insensitive unless pattern has uppercase |
| `-w` | Word boundary (whole words only) |
| `-F` | Fixed/literal strings (no regex, faster for literal searches) |
| `-e PATTERN` | Specify pattern (use multiple `-e` for OR logic) |
| `-f FILE` | Read patterns from file (one per line) |
| `-U` | Multiline mode (`.` matches newlines, patterns can span lines) |

### Output Control

| Flag | Meaning |
|------|---------|
| `-l` | List only filenames with matches |
| `-c` | Count matching lines per file |
| `--count-matches` | Count total match occurrences (not lines) |
| `-o` | Print only the matching part |
| `--json` | Structured JSON output for scripting |
| `--no-heading` | Flat output (filename:line:match per line) |
| `-q` | Quiet (exit code only, no output) |
| `--sort path` | Sort results by path |
| `--sort modified` | Sort by modification time |

### Context Lines

| Flag | Meaning |
|------|---------|
| `-A N` | N lines after each match |
| `-B N` | N lines before each match |
| `-C N` | N lines before and after each match |

### File Filtering

| Flag | Meaning |
|------|---------|
| `-t TYPE` | Include only files of this type (e.g., `rb`, `js`, `py`) |
| `-T TYPE` | Exclude files of this type |
| `-g GLOB` | Include/exclude files matching glob (prefix `!` to exclude) |
| `--hidden` | Include hidden files (`.gitignore` still applies) |
| `--no-ignore` | Ignore `.gitignore` and search all files |
| `--no-ignore-vcs` | Ignore only VCS ignore files (`.gitignore`) |
| `--follow` | Follow symlinks |

### Substitution

| Flag | Meaning |
|------|---------|
| `--replace TEXT` | Replace matches with TEXT in output (does not modify files) |
| `-r TEXT` | Alias for `--replace` |

## Common Patterns

### Find files containing a pattern

```bash
rg "TODO" --type rb
rg -l "deprecated" src/
```

### Search with context

```bash
rg -C 3 "def authenticate"      # 3 lines around each match
rg -A 5 "class User"            # 5 lines after
```

### Literal string search (no regex)

```bash
rg -F "user.email" app/
rg -F "https://api.example.com"
```

### Case-insensitive search

```bash
rg -i "error" logs/
```

### Whole-word match

```bash
rg -w "id" --type rb    # matches "id" but not "user_id"
```

### Multiple patterns (OR logic)

```bash
rg -e "foo" -e "bar" src/
```

### Multiline search

```bash
rg -U "def foo.*\n.*end" --type rb
```

### Count occurrences

```bash
rg -c "import" --type js          # matching lines per file
rg --count-matches "import"       # total match count
```

### Find by file type

```bash
rg "render" -t erb
rg "SELECT" -t sql
rg --type-list                    # show all known types
```

### Glob-based filtering

```bash
rg "TODO" -g "*.rb"
rg "secret" -g "!spec/**"         # exclude spec directory
rg "password" -g "*.{yml,yaml}"
```

### Search hidden and ignored files

```bash
rg "API_KEY" --hidden             # includes dotfiles
rg "password" --no-ignore         # ignores .gitignore
rg "token" --hidden --no-ignore   # everything
```

### Structured output for scripting

```bash
rg --json "error" | jq '.data.lines.text'
```

### Replace in output (preview changes)

```bash
rg "foo" --replace "bar"          # shows substituted output only
```

### Sort results

```bash
rg "TODO" --sort path             # alphabetical by file
rg "fix" --sort modified          # most recently modified first
```

## File Type Reference

Use `rg --type-list` to see all available types. Common ones:

- `rb` — Ruby
- `js` — JavaScript
- `ts` — TypeScript
- `py` — Python
- `go` — Go
- `rs` — Rust
- `sh` — Shell scripts
- `md` — Markdown
- `json` — JSON
- `yaml` — YAML/YML
- `sql` — SQL
- `html` — HTML
- `css` — CSS
- `erb` — ERB templates

## Behavioral Notes

- Respects `.gitignore`, `.rgignore`, `.ignore`, and `.git/info/exclude` by default.
- Skips binary files automatically.
- Outputs color by default in terminal; piped output is plain text.
- Regex flavor: Rust regex (no lookahead/lookbehind in default mode; use PCRE2 with `-P` for those).
- `-P` enables PCRE2 for lookahead, lookbehind, backreferences: `rg -P "(?<=def )\w+"`.

## Quick Reference

```bash
# Most common
rg "pattern"                          # search current dir recursively
rg "pattern" path/                    # search specific path
rg -i "pattern"                       # case insensitive
rg -w "word"                          # whole word
rg -F "literal.string"                # no regex
rg -l "pattern"                       # filenames only
rg -c "pattern"                       # count per file
rg -C 3 "pattern"                     # 3 lines context
rg -t rb "pattern"                    # ruby files only
rg -g "*.yml" "pattern"               # glob filter
rg --hidden "pattern"                 # include dotfiles
rg --no-ignore "pattern"              # ignore .gitignore
rg -e "foo" -e "bar"                  # OR patterns
rg -U "multi\nline"                   # multiline
rg --json "pattern"                   # JSON output
rg "old" -r "new"                     # preview replacement
rg --sort path "pattern"              # sorted output
rg --type-list                        # list file types
```
