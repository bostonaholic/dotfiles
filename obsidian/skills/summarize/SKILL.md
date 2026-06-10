---
name: summarize
description: 'This skill should be used when the user asks to "summarize a note", "summarize this article", "replace #summarize-later", "add a summary to a note", "generate takeaways", or mentions summarizing Obsidian notes. Replaces the #summarize-later tag with a high-level summary and actionable takeaways.'
---

# Summarize Note

Summarize an Obsidian note by replacing the `#summarize-later` tag with a structured summary and actionable takeaways. The only other change permitted is ensuring a `read-summary` tag is in the frontmatter (replacing `read-later` if present) — everything else (status, finished, other tags, etc.) remains untouched.

## Workflow

1. **Find the note** — Search the vault using Grep or Glob to locate the note by title.
2. **Read the full content** — Load the entire note to understand its argument, evidence, and conclusions.
3. **Replace `#summarize-later`** — Swap the tag with the summary block described below.
4. **Add the `read-summary` frontmatter tag** — Ensure the note carries a `read-summary` tag so it can be found as summarized-but-not-yet-read. If a `read-later` tag is present, replace it with `read-summary`; otherwise add `read-summary` to the existing tags.

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

- Do not modify any other part of the note — the only permitted changes are replacing `#summarize-later` with the summary block and ensuring the `read-summary` frontmatter tag is present (replacing `read-later` if it exists). No restructuring of existing content.
- Only replace the `#summarize-later` tag. If the tag is not found, report that to the user rather than guessing where to insert.
- Always ensure `read-summary` is in the frontmatter tags after summarizing, even when no `read-later` tag was present. If `read-summary` is already there, leave it as-is rather than duplicating it.
