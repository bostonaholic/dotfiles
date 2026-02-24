---
name: learn
description: Learn from a mistake by adding a rule to CLAUDE.md so it doesn't happen again
---

# Learn From Mistake

Review our conversation to identify the most recent mistake or correction.
Then update the appropriate CLAUDE.md so it won't happen again.

## Steps

1. **Identify the mistake**: Look at the conversation history for the most
   recent correction, mistake, or suboptimal behavior. Summarize what went
   wrong in one sentence.

2. **Draft a rule**: Write a concise, actionable rule that would prevent this
   mistake in the future. The rule should be:
   - Specific enough to be useful (not vague platitudes)
   - Written as an imperative ("Do X" or "Never Y")
   - One to two sentences max

3. **Choose the right file**: Determine which CLAUDE.md to update:
   - **Project CLAUDE.md** (`./CLAUDE.md`): if the lesson is specific to this
     project's codebase, conventions, or tooling
   - **Global CLAUDE.md** (`~/.claude/CLAUDE.md`): if the lesson applies
     across all projects (general coding habits, communication style, workflow)

4. **Check for duplicates**: Read the target CLAUDE.md and verify the rule
   doesn't already exist or overlap with an existing rule. If a related rule
   exists, refine it rather than adding a duplicate.

5. **Add the rule**: Append the rule to the most appropriate existing section,
   or create a new `## Learned Rules` section if no section fits. Keep the
   file well-organized.

6. **Show the user**: Display the exact rule you added and which file you
   updated.
