---
name: duf
description: 'This skill should be used when the user asks about disk space, disk usage, mounted filesystems, storage availability, or wants to see what is using disk space. Trigger phrases: "check disk space", "how much disk space", "what is mounted", "disk usage", "free space", "storage available", "filesystem info", "show me df", or "duf".'
---

# duf — Disk Usage/Free Utility

`duf` is a modern `df` replacement with colored output, sorting, filtering, and
JSON export. Binary: `/opt/homebrew/bin/duf`.

**User alias:** `df="duf --sort size"` — running `df` invokes `duf` sorted by
size descending.

## Basic Usage

```bash
# Default view (all real filesystems, sorted by mountpoint)
duf

# User's alias — sorted by size, largest first
df

# Specific path(s)
duf /home /var
```

## Sorting

```bash
duf --sort size        # largest first
duf --sort avail       # most free space first
duf --sort used        # most used first
duf --sort usage       # highest utilization % first
duf --sort mountpoint  # alphabetical (default)
duf --sort type        # group by device type
duf --sort filesystem  # group by fs type
```

## Filtering by Device Type

Device types: `local`, `network`, `fuse`, `special`, `loops`, `binds`

```bash
# Show only local disks
duf -only local

# Show only network mounts
duf -only network

# Hide loop devices and pseudo filesystems
duf -hide loops,special

# Show local and network but hide fuse
duf -only local,network
```

## Filtering by Filesystem Type

```bash
# Only APFS volumes
duf -only-fs apfs

# Only ext4 and xfs
duf -only-fs ext4,xfs

# Hide tmpfs and devfs
duf -hide-fs tmpfs,devfs
```

## Filtering by Mount Point

Supports wildcards (`*`):

```bash
# Only the root filesystem
duf -only-mp /

# Only /home and /var
duf -only-mp /home,/var

# Hide all snap mounts
duf -hide-mp /snap/*
```

## JSON Output (for scripting and AI agents)

Use `-json` to get machine-readable output — ideal when parsing results or
passing data to other tools:

```bash
duf --json

# Pipe into jq for filtering
duf --json | jq '.[] | select(.device_type == "local") | {mount: .mount_point, avail: .avail, size: .total}'

# Check if any filesystem is over 90% full
duf --json | jq '[.[] | select(.usage_percent > 90)] | length'

# Get available space on root in bytes
duf --json | jq '.[] | select(.mount_point == "/") | .avail'
```

JSON fields available: `device`, `device_type`, `mount_point`, `fs_type`,
`total`, `used`, `avail`, `usage_percent`, `inodes_total`, `inodes_used`,
`inodes_avail`, `inodes_usage_percent`.

## Inode Information

```bash
# Show inode counts instead of block usage
duf -inodes

# JSON with inode data
duf -inodes --json
```

Use inode mode when a filesystem reports "no space left" but block usage looks
normal — a full inode table causes the same symptom.

## Selecting Output Fields

```bash
# Minimal view: mount, size, available, usage bar
duf -output mountpoint,size,avail,usage

# All fields
duf -output mountpoint,size,used,avail,usage,inodes,inodes_used,inodes_avail,inodes_usage,type,filesystem
```

Available fields: `mountpoint`, `size`, `used`, `avail`, `usage`, `inodes`,
`inodes_used`, `inodes_avail`, `inodes_usage`, `type`, `filesystem`

## Including Hidden Filesystems

```bash
# Show everything including pseudo/duplicate/inaccessible filesystems
duf -all
```

## Style

```bash
# ASCII output (useful in environments without Unicode support)
duf -style ascii

# Default Unicode output
duf -style unicode
```

## Practical Patterns for AI Agents

**Check if disk is nearly full:**

```bash
duf --json | jq '[.[] | select(.device_type == "local" and .usage_percent > 85)] | if length > 0 then "WARNING: low disk space", . else "OK" end'
```

**Find largest local filesystem:**

```bash
duf -only local --sort size --json | jq 'first'
```

**Summarize all local volumes:**

```bash
duf -only local -output mountpoint,size,used,avail,usage
```

**Check a specific path's filesystem:**

```bash
duf /path/to/directory
```

**Get root filesystem free space in human-readable form:**

```bash
duf -only-mp / -output mountpoint,avail,usage
```

## Notes

- `duf` operates on mounted filesystems, not directories — use `dua` or `du`
  to analyze disk usage within a directory tree.
- On macOS, APFS volumes share a pool; `size` on each volume reflects the total
  pool size, not an individual partition limit.
- Color thresholds: yellow at 50% usage / 10 GB avail, red at 90% usage / 1 GB
  avail (configurable via `-usage-threshold` and `-avail-threshold`).
