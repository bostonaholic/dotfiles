---
name: learn
user-invocable: true
description: This skill should be used when the user says "learn from that mistake", "remember this for next time", "add that to CLAUDE.md", "don't do that again", or wants to codify a correction or lesson into CLAUDE.md so it persists across sessions.
---

# Learn From Mistake

Review the conversation to identify the most recent mistake or correction, then codify it as a rule in the appropriate CLAUDE.md.

## Steps

1. **Identify the mistake**: Scan the conversation history for the most recent correction, mistake, or suboptimal behavior. Summarize what went wrong in one sentence.

2. **Draft a rule**: Write a concise, actionable rule that prevents this mistake in the future. The rule should be:
   - Specific enough to be useful (not vague platitudes)
   - Written as an imperative ("Do X" or "Never Y")
   - One to two sentences max

3. **Choose the right file**: Determine which CLAUDE.md to update:
   - **Project CLAUDE.md** (`./CLAUDE.md`): for lessons specific to this project's codebase, conventions, or tooling
   - **Global CLAUDE.md** (`~/.claude/CLAUDE.md`): for lessons that apply across all projects (general coding habits, communication style, workflow)

4. **Check for duplicates**: Read the target CLAUDE.md and verify the rule doesn't already exist or overlap with an existing rule. If a related rule exists, refine it rather than adding a duplicate.

5. **Add the rule**: Append the rule to the most appropriate existing section, or create a new `## Learned Rules` section if no section fits. Keep the file well-organized.

6. **Show the user**: Display the exact rule added and which file was updated.
