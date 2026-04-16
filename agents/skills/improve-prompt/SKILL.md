---
name: improve-prompt
user-invokable: true
argument-hint: "<prompt text or file path containing the prompt to improve>"
description: "Rewrites and restructures LLM prompts to reduce token count, eliminate redundancy, and improve instruction clarity using concept elevation. Compresses disparate instructions into higher-level principles for more concise, adaptable prompts. Use when the user asks to improve a prompt, make a prompt better, optimize a prompt, refine a system prompt, or apply concept elevation."
---

# Improve Prompt Using Concept Elevation

Apply concept elevation to make prompts more concise, clear, and effective.

## Concept Elevation

Replace clusters of specific instructions with the single higher-level principle they share — making prompts shorter, clearer, and more adaptable to novel situations.

## Process

1. **Decompose**: Break the prompt into its core goals and concepts. Identify what each section is trying to achieve.

2. **Group**: Organize related concepts into clusters. Look for instructions that serve the same underlying purpose.

3. **Elevate**: For each group, find the single higher-level idea that captures the sum of the group's instructions. Iterate on candidate idea-sums until the optimal compression is found.

4. **Synthesize**: Combine the elevated concepts into a final prompt. Verify nothing was lost, then identify and fix any remaining redundancy or vagueness.

5. **Validate**: Compare the improved prompt against the original to confirm it preserves all intent while being more concise.

## Formatting

Perform each step inside `<well-named-xml-style>` tags to make the reasoning auditable.

## Quality Criteria

The improved prompt should be:
- More concise than the original (fewer tokens for the same intent)
- Clearer (less ambiguity, fewer edge cases left unaddressed)
- More adaptable (principles over rigid examples)
- Preserving of all original intent (nothing silently dropped)

## Example

**Before** (verbose, repetitive):
```
When writing code, always add comments. Make sure every function has a
docstring. Include type hints on all parameters. Add inline comments for
complex logic. Document return values. Explain any non-obvious algorithms.
```

**After** (elevated):
```
Write self-documenting code: type-annotate parameters and returns, docstring
every function, and comment non-obvious logic.
```

Six instructions compressed to one principle — same coverage, fewer tokens, more adaptable to edge cases not explicitly listed.
