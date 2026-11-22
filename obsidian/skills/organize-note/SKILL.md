---
name: organize-note
description: 'This skill should be used when the user asks to "organize a note", "link this note", "link a note to the vault", "add wiki links", "connect this note", "find unlinked mentions", "add backlinks", or mentions bi-directionally linking an Obsidian note. Turns unlinked mentions into [[wiki links]] in both directions: from the note to existing notes, and from other notes to this one.'
---

# Organize Note

Link one note into the vault in both directions:

- **Outbound** — mentions in the note of other notes' titles/aliases become `[[links]]`.
- **Inbound** — mentions of this note's title/aliases in other notes become `[[links]]`, so they show in this note's backlinks pane.

A script finds candidates and applies edits. You decide which candidates are real.

## Workflow

1. **Find the note** — locate it by title with Glob. Use its path relative to the vault root.
2. **Scan** —
   ```bash
   python3 "${CLAUDE_SKILL_DIR}/scripts/link_candidates.py" scan "<vault>" "<note path>"
   ```
   Output: JSON with `candidates` (each has `id`, `dir` in/out, `file`, `line`, `matched`, `context`, `replacement`, `ambiguous`) and `skipped_dataless`.
3. **Judge each candidate** — keep it only when the matched text refers to the target note's concept in that context. Reject:
   - Common words that happen to be note titles ("Focus", "Notes", "Work") used in their everyday sense.
   - Mentions where the target is a different thing with the same name (a person vs. a book).
   - `ambiguous` candidates (several notes share the term) unless context makes the right file obvious; otherwise skip and report.
4. **Confirm if large** — if more than 10 inbound candidates survive, list them (file, line, context) and ask the user before applying.
5. **Apply** —
   ```bash
   python3 "${CLAUDE_SKILL_DIR}/scripts/link_candidates.py" apply "<vault>" "<note path>" <id> <id> ...
   ```
   Apply all chosen ids in one call. The script re-scans, so ids stay valid only if no file changed since step 2.
6. **Report** — table of applied links (direction, file:line, before → after), rejected candidates with a one-word reason, and `skipped_dataless` if non-zero.

## What the script handles

- Skips frontmatter, headings, code, existing wiki/markdown links, URLs, tags, and HTML.
- Links only the first unlinked mention per file per target.
- Longest title wins on overlap ("Building a Second Brain" over "Second Brain").
- Writes `[[Title|matched text]]` when the text's case or wording differs from the title.
- Never links *to* `Daily Notes/` or `Weekly Notes/` (date titles); those folders are still scanned for inbound mentions.
- Skips iCloud placeholder files (`dataless`) instead of downloading them. If `skipped_dataless` is large, tell the user coverage is partial and that marking the vault folder "Keep Downloaded" in Finder fixes it.

## Constraints

- Change nothing except the chosen mentions: no frontmatter edits, no "Related" sections, no rewording.
- Do not invent links for notes that are not mentioned by title or alias. If the user wants a related note linked that has no mention, suggest adding an alias to that note instead.
- Do not create new notes for unresolved concepts.
