# claude-stream-filter.jq
# Extracts human-readable progress from Claude Code stream-json output.
# Used by claude wrapper scripts (merge-dependabots, rebase-dependabots).

if .type == "assistant" then
    .message.content[]? |
    if .type == "tool_use" then
        "▶ " + .name + ": " + (
            .input.command //
            .input.description //
            .input.pattern //
            .input.prompt //
            .input.query //
            .input.skill //
            "(running)"
        )
    elif .type == "text" then
        .text
    else empty end
elif .type == "result" then
    if .subtype == "success" then .result
    elif .subtype == "error_max_turns" then "⚠ Hit max turns: " + .result
    else "✗ Error: " + (.error // .result // "unknown")
    end
else empty end
