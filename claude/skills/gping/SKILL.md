---
name: gping
description: This skill should be used when the user asks to "ping a host", "check latency", "monitor network latency", "visualize ping", "graph ping results", "test network connectivity", "compare ping to multiple hosts", or mentions watching network response times. Note that gping is an interactive TUI — AI agents cannot run it directly for automated checks.
---

# gping - Ping with a Graph

## Overview

`gping` is an interactive terminal UI that renders real-time latency graphs for one or more hosts simultaneously. The user's shell has `ping` aliased to `gping`.

- Installed at: `/opt/homebrew/bin/gping`
- User alias: `ping="gping"`

## Critical Limitation for AI Agents

**gping is an interactive TUI and cannot be used by AI agents for automated checks.**

It renders a live graph that requires a terminal and user interaction. Invoking it via Bash in an agentic context will hang or produce no useful output.

**For programmatic connectivity checks, use alternatives instead:**

```bash
# Check if a host is reachable (exits 0/1)
/sbin/ping -c 4 google.com

# Check HTTP/HTTPS latency
curl -o /dev/null -s -w "%{time_total}\n" https://example.com

# Check DNS resolution
dig +short google.com
```

Reserve `gping` suggestions for the user to run manually in their own terminal.

## When to Suggest gping to the User

Recommend `gping` when the user wants to:

- Visually monitor latency over time (not just a single check)
- Compare latency between multiple hosts side-by-side
- Watch for latency spikes or packet loss during network debugging
- Time command execution and compare against ping (using `--cmd`)
- Monitor latency on a specific network interface

## Common Usage Patterns

### Ping one or more hosts

```bash
# Single host
gping google.com

# Multiple hosts overlaid on the same graph
gping google.com cloudflare.com 1.1.1.1
```

### Compare cloud region latency

Use cloud shorthands to ping regional endpoints without looking up IPs:

```bash
gping aws:us-east-1 aws:eu-west-1 aws:ap-southeast-1
```

Supported provider prefixes: `aws`, `gcp`, `azure` followed by a region name.

### Graph command execution time (`--cmd`)

Instead of pinging, graph how long a command takes to run repeatedly:

```bash
# Compare curl latency to two endpoints
gping --cmd "curl -s https://api.example.com/health" "curl -s https://api.backup.com/health"

# Watch a build step's duration over time
gping --cmd "make test"
```

### Control timing and buffer

```bash
# Check every 0.5 seconds (default for ping is 0.2s, for --cmd is 0.5s)
gping -n 0.5 google.com

# Show last 60 seconds of history (default is 30)
gping -b 60 google.com
```

### Force IPv4 or IPv6

```bash
gping -4 google.com   # IPv4 only
gping -6 google.com   # IPv6 only
```

### Bind to a specific network interface

```bash
gping -i en0 google.com
gping -i utun3 google.com   # e.g., VPN interface
```

### Simplify the graph rendering

```bash
# Use ASCII-compatible characters for terminals with limited font support
gping -s google.com
```

## Key Flags Reference

| Flag | Default | Purpose |
|------|---------|---------|
| `--cmd` | off | Graph command execution time instead of ICMP ping |
| `-n <seconds>` | 0.2 (ping) / 0.5 (cmd) | Poll/watch interval |
| `-b <seconds>` | 30 | Seconds of history shown in graph |
| `-4` | — | Force IPv4 resolution |
| `-6` | — | Force IPv6 resolution |
| `-i <interface>` | — | Network interface to bind |
| `-s` | off | Simple (ASCII-safe) graph characters |
| `-c <color>` | auto | Assign color to a host/command line |
| `--clear` | off | Clear graph from terminal on exit |

## Troubleshooting

- **No output / hangs in CI or agent context**: gping requires an interactive terminal. Use `/sbin/ping -c N` instead.
- **Permission denied on raw sockets**: gping uses system `ping` internally; ensure `/sbin/ping` has the setuid bit (`ls -l /sbin/ping`).
- **Cloud shorthands not resolving**: Verify the region name matches exactly (e.g., `aws:us-east-1`, not `aws:us-east1`).
