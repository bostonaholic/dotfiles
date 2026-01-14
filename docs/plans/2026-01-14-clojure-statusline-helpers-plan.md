# Plan: Clojure Statusline Helper Functions (2026-01-14)

## Summary

Add data extraction helper functions to the Clojure statusline implementation that mirror the bash script's helper functions. This creates a consistent abstraction layer for accessing JSON input data, improving readability and maintainability.

## Stakes Classification

**Level**: Low
**Rationale**: Isolated refactor within a single file. The statusline already works correctly. Adding helpers improves code organization without changing behavior. Easy rollback by reverting the file.

## Context

**Research**: `docs/plans/2026-01-01-clojure-statusline-design.md`
**Affected Areas**: `claude/statusline.clj` only

## Success Criteria

- [ ] All 13 helper functions from `statusline.sh` have Clojure equivalents
- [ ] Formatting functions use the new helpers instead of direct access
- [ ] Script produces identical output (functional equivalence)
- [ ] Code follows idiomatic Clojure patterns (pure functions, keyword access)

## Helper Functions to Implement

| Bash Function | Clojure Equivalent | JSON Path |
|--------------|-------------------|-----------|
| `get_model_name` | `get-model-name` | `[:model :display_name]` |
| `get_current_dir` | `get-current-dir` | `[:workspace :current_dir]` |
| `get_project_dir` | `get-project-dir` | `[:workspace :project_dir]` |
| `get_version` | `get-version` | `[:version]` |
| `get_cost` | `get-cost` | `[:context_window :total_cost_usd]` |
| `get_duration` | `get-duration` | `[:cost :total_duration_ms]` |
| `get_lines_added` | `get-lines-added` | `[:cost :total_lines_added]` |
| `get_lines_removed` | `get-lines-removed` | `[:cost :total_lines_removed]` |
| `get_input_tokens` | `get-input-tokens` | `[:context_window :total_input_tokens]` |
| `get_output_tokens` | `get-output-tokens` | `[:context_window :total_output_tokens]` |
| `get_context_window_size` | `get-context-window-size` | `[:context_window :context_window_size]` |
| `get_output_style` | `get-output-style` | `[:output_style :name]` |
| `get_current_usage` | `get-current-usage` | `[:context_window :current_usage]` |

## Implementation Steps

### Phase 1: Add Data Extraction Helpers

#### Step 1.1: Add helper functions section after colors

- **Files**: `claude/statusline.clj:24-26` (insert after line 26)
- **Action**: Add all 13 helper functions as pure functions that take `data` map and return extracted values with appropriate defaults
- **Verify**: Functions defined without errors (syntax check)
- **Complexity**: Small

```clojure
;; Data extraction helpers (mirrors statusline.sh helpers)
(defn get-model-name [data] (get-in data [:model :display_name] "unknown"))
(defn get-current-dir [data] (get-in data [:workspace :current_dir]))
(defn get-project-dir [data] (get-in data [:workspace :project_dir]))
(defn get-version [data] (:version data))
(defn get-cost [data] (get-in data [:context_window :total_cost_usd]))
(defn get-duration [data] (get-in data [:cost :total_duration_ms]))
(defn get-lines-added [data] (get-in data [:cost :total_lines_added]))
(defn get-lines-removed [data] (get-in data [:cost :total_lines_removed]))
(defn get-input-tokens [data] (get-in data [:context_window :total_input_tokens]))
(defn get-output-tokens [data] (get-in data [:context_window :total_output_tokens]))
(defn get-context-window-size [data] (get-in data [:context_window :context_window_size] 0))
(defn get-output-style [data] (get-in data [:output_style :name] ""))
(defn get-current-usage [data] (get-in data [:context_window :current_usage] {}))
```

### Phase 2: Refactor Formatting Functions

#### Step 2.1: Update format-directory to use helpers

- **Files**: `claude/statusline.clj:56-71`
- **Action**: Replace direct destructuring with calls to `get-current-dir` helper
- **Verify**: `echo '{"workspace":{"current_dir":"/tmp"}}' | ./statusline.clj` shows "📁 tmp"
- **Complexity**: Small

#### Step 2.2: Update format-context to use helpers

- **Files**: `claude/statusline.clj:83-99`
- **Action**: Replace direct access with `get-context-window-size` and `get-current-usage`
- **Verify**: Script produces same context bar output
- **Complexity**: Small

#### Step 2.3: Update format-cost to use helpers

- **Files**: `claude/statusline.clj:101-104`
- **Action**: Replace direct access with `get-cost`
- **Verify**: Script produces same cost output
- **Complexity**: Small

#### Step 2.4: Update format-style to use helpers

- **Files**: `claude/statusline.clj:106-109`
- **Action**: Replace direct access with `get-output-style`
- **Verify**: Script produces same style output
- **Complexity**: Small

#### Step 2.5: Update format-model to use helpers

- **Files**: `claude/statusline.clj:111-113`
- **Action**: Replace direct destructuring with `get-model-name`
- **Verify**: Script shows model name correctly
- **Complexity**: Small

### Phase 3: Verification

#### Step 3.1: End-to-end test with sample input

- **Files**: `claude/statusline.clj`
- **Action**: Run script with realistic JSON input matching Claude Code output
- **Verify**: Output matches expected format with all components
- **Complexity**: Small

#### Step 3.2: Compare outputs between bash and Clojure versions

- **Files**: `claude/statusline.sh`, `claude/statusline.clj`
- **Action**: Run both scripts with identical input, compare outputs
- **Verify**: Functionally equivalent output (colors and content match)
- **Complexity**: Small

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Breaking existing formatting | Script produces wrong output | Test with sample input after each change |
| Nil handling differences | Crashes on missing data | Use default values in get-in calls |

## Rollback Strategy

Single file change - revert with `git checkout claude/statusline.clj`

## Status

- [x] Plan approved
- [x] Implementation started
- [x] Implementation complete

## Completion Notes

All 13 helper functions added and formatting functions refactored to use them. Verified functional equivalence with bash implementation. Code review: APPROVE WITH NITS. Security review: PASS.
