---
name: ports
description: This skill should be used when the user asks "what's running on port X", "check port 3000", "find listening ports", "what process is using port X", "show running servers", or mentions checking TCP ports or processes.
---

# Ports - List Listening TCP Ports

## Overview

Check which processes are listening on TCP ports using the `ports` command available on PATH.

## Usage

```bash
# Show all listening ports
ports

# Filter by port number
ports 3000

# Filter by process name
ports ruby
```

The filter is case-insensitive and matches against the full `lsof` output (process name, PID, port number, etc.).

## When to Use

Invoke `ports` via Bash when:

- Checking if a specific port is in use before starting a server
- Identifying what process is occupying a port
- Listing all active development servers
- Debugging port conflicts

## Output

Output follows `lsof` columnar format with headers:

```text
COMMAND   PID   USER   FD   TYPE   DEVICE   SIZE/OFF   NODE   NAME
ruby    44572 matthew   8u  IPv4   0x3b...        0t0    TCP  localhost:3000 (LISTEN)
```

Key columns: COMMAND (process name), PID (process ID), NAME (address:port).

Empty output means no matching processes are listening.

## Notes

- Without `sudo`, only the current user's processes are visible
- The process name reflects the runtime (e.g. `ruby` or `node`), not the framework (e.g. `rails` or `next`)
- Both IPv4 and IPv6 bindings appear as separate entries for the same port
