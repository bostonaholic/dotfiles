---
name: redo
user-invokable: true
description: This skill should be used when the user says "redo this", "start over", "scrap this approach", "rewrite from scratch", "try a simpler approach", or wants to discard the current implementation and reimplement with an elegant solution using everything learned so far.
---

# Elegant Redo

After working through a problem and gaining deep context about the codebase, constraints, and edge cases, step back, discard the current approach, and reimplement from scratch with the simplest, most elegant solution.

## Steps

1. **Synthesize what was learned**: Review the conversation history. Identify:
   - The core problem being solved
   - Constraints and edge cases discovered along the way
   - What made the current approach complex or unsatisfying
   - Any insights that only became clear after working through it

2. **Identify the essential complexity**: Separate what is truly necessary from accidental complexity. Ask: "What is the minimum viable design if explained to a senior engineer with full context?"

3. **Design the elegant solution**: Before writing any code, describe the new approach in 3-5 sentences. It should be:
   - Simpler than what exists (fewer moving parts, less indirection)
   - More direct (shortest path from input to output)
   - Obvious in hindsight ("of course it should work this way")

4. **Confirm with the user**: Present the new design and get approval before proceeding. Explain what changes and why it is better.

5. **Implement cleanly**: Rewrite from scratch rather than patching. Do not carry forward unnecessary abstractions, workarounds, or dead code from the previous attempt.

6. **Verify**: Run tests, linters, and any relevant quality gates to confirm the new implementation is correct.

## Guiding Principles

- "Perfection is achieved not when there is nothing more to add, but when there is nothing left to take away." — Antoine de Saint-Exupery
- The best code is code that doesn't exist. Delete aggressively.
- If the elegant solution is what already exists, say so. Do not rewrite for the sake of rewriting.
