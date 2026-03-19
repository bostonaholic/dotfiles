---
description: Summarize an Obsidian note by replacing #summarize-later with a high-level summary of its content
arguments:
  - name: title
    description: The title of the note to summarize (e.g. "How Do You Want to Remember?")
    required: true
---

# Summarize Note

Find the note titled "$ARGUMENTS.title" in the vault by searching for it with Grep or Glob.

Read the full note content.

Replace the `#summarize-later` tag with a high-level summary followed by actionable takeaways.

## Summary

Write a single paragraph (3-6 sentences) that:

- Captures the core argument or thesis, not just the topic
- Includes key findings, numbers, or outcomes if present
- Is written in plain prose, not bullet points
- Matches the tone of a knowledgeable peer explaining what the article is about

## Actionable Takeaways

Below the summary paragraph, add a sub-section:

```
### Actionable Takeaways
```

List 2-5 concrete actions the reader can take based on the content. Each takeaway should:

- Start with a verb (e.g. "Try", "Start", "Replace", "Ask", "Schedule")
- Be specific enough to act on today, not vague advice
- Connect directly to something discussed in the note
- Be relevant to someone in a knowledge work or software engineering context when possible

Do not modify any other part of the note.
