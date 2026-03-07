---
name: bat
description: >
  This skill should be used when the user asks to view files with syntax
  highlighting, inspect file contents with line numbers, see git diff
  integration in file output, or use bat as a modern cat replacement.
  Trigger phrases: "show me the file with highlighting", "view file with
  line numbers", "bat the file", "show git changes in file", "preview file
  contents", "cat the file", "read file with syntax highlighting".
---

# bat — Syntax-Highlighted File Viewer

`bat` is a `cat(1)` clone with syntax highlighting, Git integration, and
configurable output styles. Installed at `/opt/homebrew/bin/bat`.

## User Alias

The user has configured:

```sh
alias cat="bat --style=plain --paging=never"
```

This means invoking `cat` already uses bat with plain output and no pager.
Use `bat` directly (not `cat`) when syntax highlighting or other features
are needed.

## Core Usage Patterns

### View a file with syntax highlighting

```sh
bat path/to/file.rs
bat src/main.py
```

### View a file without decoration (equivalent to cat)

```sh
bat --style=plain --paging=never path/to/file
```

### View with line numbers only

```sh
bat --style=numbers path/to/file
bat -n path/to/file
```

### View a specific line range

```sh
bat -r 10:50 path/to/file       # lines 10 through 50
bat -r 100:200 path/to/file     # lines 100 through 200
bat -r :30 path/to/file         # lines 1 through 30
bat -r 50: path/to/file         # line 50 to end of file
```

### View multiple files

```sh
bat file1.rs file2.rs file3.rs
bat src/*.ts
```

### Pipe stdin through bat

```sh
echo "hello world" | bat
curl -s https://example.com/script.sh | bat -l sh
command_with_output | bat --paging=never
```

### Force a specific syntax language

```sh
bat -l json output.log
bat -l yaml config
bat -l markdown README
bat --language python script
```

Use `-l` when the file extension is missing or incorrect.

### Show git diff highlights

```sh
bat --diff path/to/file
```

Highlights lines that have changed since the last git commit. Only shows
modified lines and their surrounding context.

### Apply a theme

```sh
bat --theme=TwoDark path/to/file
bat --theme=Dracula path/to/file
bat --theme=GitHub path/to/file
```

List available themes:

```sh
bat --list-themes
```

## Key Flags Reference

| Flag | Short | Description |
|------|-------|-------------|
| `--style=STYLE` | | Output style (see below) |
| `--paging=WHEN` | | Pager control: `auto`, `always`, `never` |
| `--language=LANG` | `-l` | Force syntax language |
| `--line-range=N:M` | `-r` | Show only lines N through M |
| `--number` | `-n` | Show line numbers |
| `--diff` | `-d` | Show only changed lines (git diff mode) |
| `--theme=NAME` | | Use a specific color theme |
| `--list-themes` | | Print all available themes |
| `--list-languages` | | Print all supported languages |
| `--plain` | `-p` | Equivalent to `--style=plain --paging=never` |
| `--unbuffered` | `-u` | Flush output on every line (useful in pipes) |

## Style Options

Pass one or more comma-separated values to `--style`:

| Value | Effect |
|-------|--------|
| `plain` | No decorations — just the file contents |
| `numbers` | Line numbers in the gutter |
| `grid` | Horizontal rule separating header from body |
| `header` | File name header above output |
| `header-filename` | File name only (no language info) |
| `changes` | Git change markers in the gutter |
| `full` | All decorations enabled |

Examples:

```sh
bat --style=numbers,grid path/to/file
bat --style=header,numbers path/to/file
bat --style=full path/to/file
```

## Paging Control

By default bat uses a pager for long files. Override with:

```sh
bat --paging=never path/to/file    # never page (stream output)
bat --paging=always path/to/file   # always page even for short files
bat --paging=auto path/to/file     # page only if output exceeds terminal height
```

When capturing output in scripts or pipes, always use `--paging=never`.

## Common Scenarios

### Inspect a config file before editing

```sh
bat --style=numbers ~/.config/nvim/init.lua
```

### Review a script before running it

```sh
bat -l bash script.sh
```

### View a log file without overwhelming the terminal

```sh
bat --paging=never --style=plain application.log | tail -n 100
```

### Show what changed in a file since the last commit

```sh
bat --diff --style=changes,numbers src/app.rs
```

### Compare file section with highlighted context

```sh
bat -r 45:75 --style=numbers src/parser.py
```

### Syntax-highlight arbitrary stdin

```sh
pbpaste | bat -l json
heroku logs | bat -l log --paging=never
```

## Tips for Agent Use

- Prefer `bat --paging=never` in all non-interactive or scripted contexts to
  prevent blocking on pager input.
- Use `-l` to force language detection when reading files without standard
  extensions (e.g., `.conf`, `.log`, lock files, dotfiles).
- `--diff` only works inside a git repository; fall back to plain output
  outside git repos.
- When the user's `cat` alias is sufficient (plain output, no pager), call
  `cat` directly. Use `bat` explicitly only when richer output is needed.
- `bat --list-languages` shows all ~200 supported syntaxes with their
  associated file extensions.
