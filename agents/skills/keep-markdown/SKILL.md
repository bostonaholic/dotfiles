---
name: "keep-markdown"
description: "Search and retrieve saved web content as clean Markdown with the keep.md CLI."
---

# keep-markdown

Search and retrieve saved web content as clean Markdown with the keep.md CLI. Users save web pages via the keep.md browser extension or CLI, and this skill lets you search, list, and read that content.

## Authentication

You need an API key to use keep.md. The user must provide one or have it set in their environment.

1. Sign up at <https://keep.md>
2. Go to <https://keep.md/dashboard>
3. Create a **personal** API token
4. Save the key:

```bash
npm i -g keep-markdown
keep key <your-token>
```

This persists the key to `~/.config/keep/config.json`. Alternatively set the `KEEP_API_KEY` environment variable.

## CLI Commands

Install globally once, then use the `keep` command.

### Check account info

```bash
keep me
```

Returns account info.

### List saved items

```bash
keep list
```

Returns items with status `stashed` (the default). Archived items are excluded unless you filter by status explicitly.

### List items from the last 7 days

```bash
keep list --since 7d
```

### List items with their Markdown content included

```bash
keep list --since 24h --content
```

### Search items by keyword

```bash
keep search "react hooks"
```

Searches across titles, URLs, notes, and tags. This is equivalent to `list --query "react hooks"`.

### List with query flag

```bash
keep list --query "typescript" --limit 10
```

### Get item metadata by ID

```bash
keep get <id>
```

Returns JSON with the item's URL, title, tags, status, and timestamps.

### Get item content as Markdown

```bash
keep content <id>
```

Returns the extracted Markdown content of the saved page. This is the primary way to read saved web content.

### Archive an item

```bash
keep archive <id>
```

Sets the item status to `archived`. Archived items no longer appear in `keep list` or `GET /api/items` by default. Use `--status archived` to view them.

### List unprocessed items (agent feed)

```bash
keep feed
```

Returns items that have not been marked as processed. Content is included by default. This is the primary command for agent consumption — fetch new items, process them, then mark as done.

### List unprocessed items from the last 7 days

```bash
keep feed --since 7d
```

### List unprocessed items as JSON

```bash
keep feed --json
```

### Mark items as processed

```bash
keep processed <id> [id...]
```

After an agent has consumed items from `keep feed`, mark them as processed so they won't appear in future feed requests.

### List archived items

```bash
keep list --status archived
```

### List all items including archived

```bash
keep list --status stashed,archived
```

### Get usage statistics

```bash
keep stats
```

### Get stats for a date range

```bash
keep stats --since 30d
```

### Output raw JSON

Any command supports `--json` for machine-readable output:

```bash
keep list --since 7d --json
```

## Common Workflows

### Find and read a saved article

First search for it:

```bash
keep search "article title"
```

Then read the content using the item ID from the results:

```bash
keep content <id>
```

### List recent saves with content

```bash
keep list --since 7d --content --json
```

### Archive an item after reading it

```bash
keep archive <id>
```

### View archived items

```bash
keep list --status archived
```

### Agent feed loop (fetch, process, mark done)

Fetch unprocessed items with content:

```bash
keep feed --json
```

After your agent has processed the items, mark them as done using the IDs:

```bash
keep processed <id1> <id2> <id3>
```

Only unprocessed items appear in the feed, so the next call to `keep feed` returns only new items.
