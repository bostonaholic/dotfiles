# Clojure Statusline Script Design

Compare Clojure/Babashka implementation with existing bash `statusline.sh` to evaluate code clarity for potential broader adoption in dotfiles scripts.

## Goals

- **Primary**: Code clarity comparison between bash and idiomatic Clojure
- **Secondary**: Performance benchmarking (both versions)
- **Location**: `claude/statusline.clj` alongside existing `statusline.sh`

## Architecture

### Data-First Approach

Parse JSON once into a Clojure map, thread through pure functions:

```clojure
(-> (parse-input)
    (assoc :git (get-git-info))
    (format-status-line)
    (println))
```

### Pure Formatting Functions

Each component returns a formatted string or nil:

- `format-directory` - Git repo name or path
- `format-git-info` - Branch, dirty marker, ahead count
- `format-context` - Context window progress bar with colors
- `format-cost` - Session cost in USD
- `format-style` - Output style if not default
- `format-model` - Current model name

### Git Integration

Structured git data gathering:

```clojure
(defn get-git-info [cwd]
  (when (git-repo? cwd)
    {:root   (git-root cwd)
     :branch (git-branch cwd)
     :dirty? (git-dirty? cwd)
     :ahead  (git-ahead-count cwd)}))
```

### ANSI Colors

Named color map instead of inline escape codes:

```clojure
(def colors
  {:reset "\033[0m" :red "\033[31m" :yellow "\033[33m"
   :cyan "\033[36m" :magenta "\033[35m" :gray "\033[90m" :white "\033[37m"})

(defn colorize [color text]
  (str (colors color) text (:reset colors)))
```

## Benchmarking

Both versions benchmarked with `--benchmark` flag:
- 100 iterations with timing
- Same test input JSON for fair comparison

## Deliverables

| File | Purpose |
|------|---------|
| `claude/statusline.clj` | Main Clojure script (~80-100 lines) |
| `claude/statusline-benchmark.sh` | Wrapper to benchmark bash version |
| `claude/test-input.json` | Sample Claude Code JSON for testing |

## Expected Comparison Points

1. Line count (bash ~190 vs Clojure ~80-100)
2. Readability (subjective)
3. Performance (ms per invocation)
