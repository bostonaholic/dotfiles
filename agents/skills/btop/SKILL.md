---
name: btop
description: This skill should be used when the user asks to "open btop", "launch the system monitor", "show resource usage", "check CPU/memory", "monitor processes", "open top", or when investigating system performance issues. Also use when the user wants to filter processes, change btop presets, or configure the btop layout. Note: btop is an interactive TUI — AI agents cannot operate it directly and must use programmatic alternatives for automated monitoring.
---

# btop

btop is a resource monitor and process manager TUI. The user has aliased
`top` to `btop`, so `top` launches btop.

Binary: `/opt/homebrew/bin/btop`

## Key Limitation for AI Agents

btop is an **interactive terminal UI** — it cannot be used programmatically
by AI agents. Launching btop in a subshell hangs waiting for user input.
When the user asks to "check what's using CPU" or "show memory usage", use
the [programmatic alternatives](#programmatic-alternatives) below instead.

Suggest btop to the user when they want to interactively explore and manage
processes themselves.

## CLI Flags

```text
btop [options]

-p <0-9>   Start with preset layout (0 = default, 1-9 = alternates)
-f <str>   Start with process filter pre-filled
-u <ms>    Update interval in milliseconds (default: 2000)
-t         Force TTY mode (simplified, no mouse)
-l         Low color mode (reduces color depth)
--utf-force  Force UTF-8 even if locale says otherwise
--themes-dir <path>  Load themes from custom directory
```

## Common User Requests

**Open btop normally:**

```bash
btop
```

**Open with a preset layout:**

```bash
btop -p 2
```

**Open with a process filter pre-filled:**

```bash
btop -f ruby
```

**Open with faster updates (500ms):**

```bash
btop -u 500
```

## Config File

Location: `~/.config/btop/btop.conf`

Key settings users may want to adjust:

- `color_theme` — theme name (files in `~/.config/btop/themes/`)
- `update_ms` — update interval in ms
- `proc_sorting` — default sort column (`cpu`, `mem`, `pid`, `name`)
- `proc_reversed` — reverse sort order (`true`/`false`)
- `cpu_graph_upper` / `cpu_graph_lower` — what to graph in CPU box

## Programmatic Alternatives

When an AI agent needs system stats without user interaction:

**CPU usage (all cores):**

```bash
sysctl -n hw.logicalcpu              # core count
top -l 1 -n 0 | grep "CPU usage"    # snapshot CPU %
```

**Memory usage:**

```bash
vm_stat                              # raw page stats
top -l 1 -n 0 | grep PhysMem        # summary line
```

**Process list (sorted by CPU):**

```bash
ps aux --sort=-%cpu | head -20
```

**Process list (sorted by memory):**

```bash
ps aux --sort=-%mem | head -20
```

**Find what's using a port or resource:**

```bash
lsof -i :3000                        # by port
lsof -p <pid>                        # by process
```

**Disk I/O snapshot:**

```bash
iostat -d 1 3                        # 3 samples, 1s interval
```
