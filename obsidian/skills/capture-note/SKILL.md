---
name: capture-note
description: 'This skill should be used when the user asks to "capture a URL", "capture this link", "clip this article", "save this to the vault", "add this video/book/podcast to Obsidian", or pastes a URL to add to the vault. Creates a note from a URL using the vault''s templates: articles, videos and podcasts go to Clippings/ with full content; books go to References/.'
---

# Capture Note

Turn a URL into a vault note that matches the existing templates. This is the Capture step of CODE; `organize-note` and `distill-note` come after.

A script does the fetching, duplicate check and file writing. You decide the type, title and authors.

## Workflow

1. **Inspect** —
   ```bash
   python3 "${CLAUDE_SKILL_DIR}/scripts/capture_note.py" inspect "<vault>" "<url>"
   ```
   If `existing` is set, stop and report that note's path. The URL is already captured.
2. **Decide the fields** from the inspect output:
   - **type**: start from `guessed_type`. Override when the content says otherwise: a book's publisher page → `book`; a podcast episode page on the show's own site → `podcast`.
   - **title**: use `safe_title` unless it carries site noise (" | Site Name", "- YouTube") or, for a book, a subtitle, author or edition text. A book note's title is the book title only.
   - **authors**: use `authors` unless they are wrong or empty. X/Twitter posts use the handle (`@name`), matching existing clippings. A YouTube video uses the channel name.
   - **recommended by**: only when the user says who recommended it.
3. **Write** —
   ```bash
   python3 "${CLAUDE_SKILL_DIR}/scripts/capture_note.py" write "<vault>" "<url>" --type <type> [--title "<title>"] [--author "<name>"]... [--recommended-by "<name>"]...
   ```
   Pass `--author` once per author. Passing any `--author` replaces the extracted list.
4. **Report** — the note path, type, authors, and the next step: `/distill-note <title>` for clippings (the note carries `#summarize-later`), `/organize-note <title>` for books.

## Note shapes the script writes

| Type | Folder | Frontmatter | Body |
|---|---|---|---|
| article | `Clippings/` | tags `clippings`, `read-later`; `[[Articles]]` | `## Summary` + `#summarize-later`, `## Content` |
| video | `Clippings/` | tags `clippings`, `watch-later`; `[[Videos]]` | same, content includes the transcript |
| podcast | `Clippings/` | tags `clippings`, `read-later`; `[[Podcasts]]` | same |
| book | `References/` | Books template: `read-later`, `[[Books]]` | `## Summary`, `## Notes` |

## Errors

- `defuddle failed` or `extracted no content`: the page needs a login, blocks scripted fetches, or renders with JavaScript only. Tell the user to clip it with Obsidian Web Clipper instead.
- `a note with this title already exists`: a different URL produced the same title. Ask the user whether it is the same item; if not, rerun `write` with a distinguishing `--title`.

## Constraints

- Do not edit the extracted content, and do not fill `topics`, `related`, `projects`, `areas` or `finished`.
- Do not write the summary here. Distilling is the `distill-note` skill's job.
- Do not create notes for authors.
