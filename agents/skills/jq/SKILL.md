---
name: jq
description: "Writes, explains, and debugs jq commands for parsing, filtering, transforming, and reshaping JSON data on the command line. Covers filter construction, built-in functions, format conversions (JSON to CSV/TSV), multi-file operations, and advanced patterns. Use when the user asks to parse, filter, transform, extract, query, format, convert, reshape, or merge JSON data using jq."
---

# jq — Command-Line JSON Processor

jq (v1.8.1) is installed at `/opt/homebrew/bin/jq`. It reads JSON from stdin
or files, applies filters, and outputs transformed JSON. Prefer jq over
writing custom scripts for JSON manipulation in shell pipelines.

## Core Concepts

Filters connect with `|` (pipe) and produce zero or more outputs. `.` is identity.

```bash
# Field access and nesting
echo '{"user":{"id":1}}' | jq '.user.id'

# Array iteration and filtering
echo '[1,2,3,4]' | jq 'map(select(. > 2))'  # [3,4]

# Object construction
echo '{"first":"Ada","last":"Lovelace","age":36}' | jq '{name: .first, surname: .last}'

# Computed keys
echo '{"key":"color","val":"blue"}' | jq '{(.key): .val}'
```

## Essential Command-Line Flags

| Flag | Purpose |
|------|---------|
| `-r` | Raw string output (no quotes) |
| `-R` | Raw input (treat each line as string) |
| `-s` | Slurp all inputs into one array |
| `-n` | Null input (use with `input`/`inputs`) |
| `-c` | Compact output (one line) |
| `-S` | Sort object keys |
| `-e` | Set exit status based on output (false/null = 1) |
| `--arg k v` | Bind string variable `$k` |
| `--argjson k v` | Bind JSON variable `$k` |
| `--slurpfile k f` | Load file into `$k` as array |
| `--rawfile k f` | Load file into `$k` as string |
| `--tab` | Indent with tabs |
| `--indent n` | Set indentation level |

## Common Patterns

### Extract and reshape

```bash
# Extract nested field from array of objects
cat data.json | jq '.[].user.email'

# Reshape array of objects
cat data.json | jq '[.[] | {id: .id, name: .name}]'

# Flatten nested arrays
cat data.json | jq '[.[][] ]'
# or
cat data.json | jq 'flatten'
```

### Filter and search

```bash
# Filter by condition
jq '[.[] | select(.status == "active")]' users.json

# Filter with regex
jq '[.[] | select(.name | test("^A"))]' users.json

# Check key existence
jq '[.[] | select(has("email"))]' users.json
```

### Aggregate and summarize

```bash
# Count elements
jq 'length' data.json

# Sum a field
jq '[.[].price] | add' orders.json

# Group and count
jq 'group_by(.category) | map({key: .[0].category, count: length})' items.json

# Min/max by field
jq 'min_by(.age)' people.json
```

### Transform and update

```bash
# Update a field
jq '.version = "2.0"' package.json

# Update nested with |=
jq '.config.timeout |= . + 10' settings.json

# Add field to all array elements
jq '[.[] | . + {processed: true}]' items.json

# Delete a field
jq 'del(.metadata)' data.json
```

### Format conversion

```bash
# JSON to CSV
jq -r '.[] | [.name, .age, .email] | @csv' users.json

# JSON to TSV
jq -r '.[] | [.id, .status] | @tsv' records.json

# URL-encode a value
jq -r '.query | @uri' params.json

# Shell-safe escaping
jq -r '.filename | @sh' config.json

# Base64 encode/decode
jq -r '.data | @base64' payload.json
jq -r '.encoded | @base64d' payload.json
```

### Multi-file and variable operations

```bash
# Pass shell variables into jq
jq --arg name "$USER" '.users[] | select(.name == $name)' db.json

# Pass JSON values
jq --argjson threshold 100 '[.[] | select(.count > $threshold)]' data.json

# Merge two JSON files
jq -s '.[0] * .[1]' defaults.json overrides.json

# Process multiple inputs with reduce
jq -n '[inputs]' file1.json file2.json
```

### String operations

```bash
# String interpolation
jq -r '"User: \(.name) (age \(.age))"' user.json

# Split and join
jq '.path | split("/") | last' config.json

# Replace with regex
jq '.text | gsub("old"; "new")' doc.json

# Trim whitespace
jq '.value | trim' data.json
```

## Quick Reference — Key Built-in Functions

| Category | Functions |
|----------|-----------|
| **Array** | `map`, `select`, `empty`, `add`, `sort_by`, `group_by`, `unique_by`, `flatten`, `reverse`, `first`, `last`, `range`, `limit`, `nth`, `transpose`, `combinations` |
| **Object** | `keys`, `values`, `has`, `in`, `to_entries`, `from_entries`, `with_entries`, `del`, `pick` |
| **String** | `test`, `match`, `capture`, `scan`, `split`, `join`, `sub`, `gsub`, `ltrimstr`, `rtrimstr`, `trim`, `ascii_downcase`, `ascii_upcase`, `startswith`, `endswith`, `explode`, `implode` |
| **Type** | `type`, `length`, `utf8bytelength`, `tostring`, `tonumber`, `arrays`, `objects`, `strings`, `numbers`, `booleans`, `nulls`, `scalars`, `iterables`, `values` |
| **Math** | `floor`, `ceil`, `round`, `sqrt`, `pow`, `log`, `exp`, `fabs`, `abs`, `sin`, `cos`, `atan`, `nan`, `infinite`, `isinfinite`, `isnan` |
| **Date** | `now`, `todate`, `fromdate`, `todateiso8601`, `fromdateiso8601`, `strftime`, `strptime`, `gmtime`, `mktime` |
| **Path** | `path`, `paths`, `leaf_paths`, `getpath`, `setpath`, `delpaths` |
| **Format** | `@csv`, `@tsv`, `@json`, `@html`, `@uri`, `@urid`, `@sh`, `@base64`, `@base64d`, `@text` |
| **I/O** | `input`, `inputs`, `debug`, `stderr`, `halt`, `halt_error`, `error`, `env`, `$ENV` |
| **SQL-style** | `INDEX`, `IN`, `GROUP_BY`, `UNIQUE_BY`, `JOIN` |

## Operator Reference

| Operator | Purpose |
|----------|---------|
| `\|` | Pipe (chain filters) |
| `,` | Multiple outputs |
| `?` | Suppress errors (try) |
| `//` | Alternative (default for null/false) |
| `\|=` | Update in place |
| `+=` `-=` `*=` `/=` `%=` `//=` | Arithmetic update |
| `as $var` | Variable binding |
| `..` | Recursive descent |

## Error Handling

```bash
# Suppress errors with ?
jq '.foo.bar?' data.json

# Try-catch
jq 'try .foo.bar catch "default"' data.json

# Exit status for scripting
if jq -e '.enabled' config.json > /dev/null 2>&1; then
  echo "Feature is enabled"
fi
```

## Agent-Specific Notes

- Always use `-r` when output feeds into other shell commands (avoids quoted strings)
- Use `-e` in conditionals to leverage jq's exit status
- Use `--arg` / `--argjson` to pass shell variables — never interpolate variables into jq programs directly (injection risk)
- Use `-c` for compact output when piping JSON between commands
- Use `-s` (slurp) to process multiple JSON objects as a single array
- Combine with `curl -s` for API response processing: `curl -s url | jq '.data'`

## Additional Resources

### Reference Files

For detailed function signatures and advanced patterns, consult:

- **`references/filters.md`** — Complete built-in function reference organized by category with signatures and examples
- **`references/advanced.md`** — Advanced patterns: `reduce`, `foreach`, streaming, recursive processing, custom functions, and complex data transformations
