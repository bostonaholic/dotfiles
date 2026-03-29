---
name: improve-prompt
user-invocable: true
argument-hint: "<prompt text or file path containing the prompt to improve>"
description: This skill should be used when the user asks to "improve a prompt", "make this prompt better", "optimize this prompt", "refine this system prompt", or wants to apply concept elevation to compress and clarify LLM instructions.
---

# Improve Prompt Using Concept Elevation

Apply concept elevation to make prompts more concise, clear, and effective.

## Concept Elevation

Concept elevation takes stock of disparate yet connected instructions in a prompt, then finds higher-level, clearer ways to express the sum of the ideas in a compressed form. This makes the LLM more adaptable to new situations instead of relying solely on specific examples or instructions.

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
