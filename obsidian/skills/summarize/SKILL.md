---
name: summarize
description: 'This skill should be used when the user asks to "summarize a note", "summarize this article", "replace #summarize-later", "add a summary to a note", "generate takeaways", or mentions summarizing Obsidian notes. Replaces the #summarize-later tag with a high-level summary and actionable takeaways.'
---

# Summarize Note

Summarize an Obsidian note by replacing the `#summarize-later` tag with a structured summary and actionable takeaways. No other part of the note is modified — frontmatter (tags, status, finished, etc.) remains untouched.

## Workflow

1. **Find the note** — Search the vault using Grep or Glob to locate the note by title.
2. **Read the full content** — Load the entire note to understand its argument, evidence, and conclusions.
3. **Replace `#summarize-later`** — Swap the tag with the summary block described below.

## Summary Format

Replace `#summarize-later` with a single paragraph (3-6 sentences) that:

- Captures the core argument or thesis, not just the topic
- Includes key findings, numbers, or outcomes if present
- Is written in plain prose, not bullet points
- Matches the tone of a knowledgeable peer explaining what the article is about

## Actionable Takeaways

Immediately below the summary paragraph, add:

```
### Actionable Takeaways
```

List 2-5 concrete actions the reader can take based on the content. Each takeaway:

- Starts with a verb (e.g. "Try", "Start", "Replace", "Ask", "Schedule")
- Is specific enough to act on today, not vague advice
- Connects directly to something discussed in the note
- Is relevant to someone in a knowledge work or software engineering context when possible

## Constraints

- Do not modify any other part of the note — no frontmatter changes, no restructuring existing content.
- Only replace the `#summarize-later` tag. If the tag is not found, report that to the user rather than guessing where to insert.
