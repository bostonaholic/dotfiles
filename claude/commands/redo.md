---
name: redo
description: Scrap the current approach and reimplement the elegant solution, using everything learned so far
---

# Elegant Redo

You've been working on something and now have deep context about the problem,
the codebase, and the constraints. Step back, discard the current approach, and
reimplement from scratch with the simplest, most elegant solution.

## Steps

1. **Synthesize what you've learned**: Review the conversation history. Identify:
   - The core problem being solved
   - Constraints and edge cases discovered along the way
   - What made the current approach complex or unsatisfying
   - Any insights that only became clear after working through it

2. **Identify the essential complexity**: Separate what's truly necessary from
   accidental complexity. Ask: "If I were explaining this to a senior engineer
   with full context, what's the minimum viable design?"

3. **Design the elegant solution**: Before writing any code, describe the new
   approach in 3-5 sentences. It should be:
   - Simpler than what exists (fewer moving parts, less indirection)
   - More direct (shortest path from input to output)
   - Obvious in hindsight ("of course it should work this way")

4. **Confirm with the user**: Present the new design and get approval before
   proceeding. Explain what changes and why it's better.

5. **Implement cleanly**: Rewrite from scratch rather than patching. Do not
   carry forward unnecessary abstractions, workarounds, or dead code from the
   previous attempt.

6. **Verify**: Run tests, linters, and any relevant quality gates to confirm
   the new implementation is correct.

## Guiding Principles

- "Perfection is achieved not when there is nothing more to add, but when there
  is nothing left to take away." — Antoine de Saint-Exupery
- The best code is code that doesn't exist. Delete aggressively.
- If the elegant solution is what you already have, say so. Don't rewrite for
  the sake of rewriting.
