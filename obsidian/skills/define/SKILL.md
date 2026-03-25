---
name: define
description: This skill should be used when the user asks to "define a term", "add a definition", "replace `define-later`", "define this note", or mentions defining terms in Obsidian notes. Replaces the `#define-later` tag with a concise definition derived from the note's title.
---

# Define Term

Define a term by replacing the `#define-later` tag with a short, plain-language definition. The term to define is taken from the note's title. No other part of the note is modified.

## Workflow

1. **Find the note** — Search the vault using Grep or Glob to locate the note by title.
2. **Read the full content** — Load the note to understand any existing context.
3. **Replace `#define-later`** — Swap the tag with the definition described below.

## Definition Format

Replace `#define-later` with 1-3 sentences that:

- Define the term from the note's title in plain language
- Are concise and direct — no preamble, no filler
- Capture what it is, not its full history or every nuance
- Use the tone of a knowledgeable peer giving a quick explanation

Do not add headings, bullet points, or any other structural elements — just the definition text.

## Constraints

- Do not modify any other part of the note — no frontmatter changes, no restructuring existing content.
- Only replace the `#define-later` tag. If the tag is not found, report that to the user rather than guessing where to insert.
