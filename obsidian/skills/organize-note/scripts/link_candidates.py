#!/usr/bin/env python3
"""Find and apply unlinked mentions between one Obsidian note and the rest of the vault.

  scan  <vault> <note>            -> JSON candidates (outbound + inbound), each with an id
  apply <vault> <note> <id>...    -> rewrite the chosen mentions as [[wiki links]]

Outbound: titles/aliases of other notes mentioned unlinked in <note>.
Inbound:  unlinked mentions of <note>'s title/aliases in other notes.
Only the first unlinked mention per (file, target) pair is a candidate.

iCloud placeholder files (dataless) are skipped, never downloaded; the
skipped count is reported so the caller knows coverage is partial.
"""
import json
import os
import re
import stat
import sys

SKIP_DIRS = {".obsidian", ".omc", ".claude", ".git", ".trash", "Templates", "Attachments"}
SKIP_ROOT_FILES = {"AGENTS.md", "CLAUDE.md"}  # agent instructions, not notes
NO_TARGET_DIRS =("Daily Notes/", "Weekly Notes/")  # date titles: never link *to* them
MIN_TERM_LEN = 3
SF_DATALESS = getattr(stat, "SF_DATALESS", 0x40000000)

MASK_PATTERNS = [
    re.compile(r"^```.*?^```[^\n]*$", re.S | re.M),  # fenced code
    re.compile(r"^#{1,6} .*$", re.M),                 # headings
    re.compile(r"`[^`\n]*`"),                         # inline code
    re.compile(r"!?\[\[[^\]]*\]\]"),                  # wiki links / embeds
    re.compile(r"!?\[[^\]\n]*\]\([^)\n]*\)"),         # markdown links
    re.compile(r"<[^>\n]+>"),                         # html tags / autolinks
    re.compile(r"https?://\S+"),                      # bare urls
    re.compile(r"(?<!\w)#[\w/-]+"),                   # tags
]


def is_dataless(path):
    return bool(os.stat(path).st_flags & SF_DATALESS)


def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read()


def frontmatter_end(text):
    if not text.startswith("---\n"):
        return 0
    end = text.find("\n---", 4)
    return 0 if end == -1 else end + 4


def parse_aliases(text):
    fm = text[: frontmatter_end(text)]
    m = re.search(r"^aliases:[ \t]*(.*)$", fm, re.M)
    if not m:
        return []
    inline = m.group(1).strip()
    if inline:
        items = inline.strip("[]").split(",")
    else:
        # list items until the next top-level key
        block = fm[m.end():]
        nxt = re.search(r"^\S", block[1:], re.M)
        block = block[: nxt.start() + 1] if nxt else block
        items = re.findall(r"^\s+-\s+(.*)$", block, re.M)
    return [i.strip().strip("'\"") for i in items if i.strip().strip("'\"")]


def masked(text):
    """Return text with non-linkable regions replaced by NULs (same length)."""
    chars = list(text)
    fm = frontmatter_end(text)
    for i in range(fm):
        chars[i] = "\0"
    for pat in MASK_PATTERNS:
        for m in pat.finditer(text):
            for i in range(m.start(), m.end()):
                chars[i] = "\0"
    return "".join(chars)


def term_regex(terms):
    alts = sorted(set(terms), key=len, reverse=True)
    body = "|".join(re.escape(t) for t in alts)
    return re.compile(rf"(?<![\w\[|])({body})(?![\w\]])", re.I)


def walk(vault):
    for root, dirs, files in os.walk(vault):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS and not d.startswith(".")]
        for f in files:
            if root == vault and f in SKIP_ROOT_FILES:
                continue
            if f.endswith(".md"):
                yield os.path.join(root, f)


def build_index(vault, skipped):
    """term(lower) -> list of (title, path). Titles come from filenames; aliases need file reads."""
    index = {}
    for path in walk(vault):
        rel = os.path.relpath(path, vault)
        if rel.startswith(NO_TARGET_DIRS):
            continue
        title = os.path.basename(path)[:-3]
        terms = [title]
        if is_dataless(path):
            skipped.add(rel)
        else:
            terms += parse_aliases(read(path))
        for t in terms:
            if len(t) >= MIN_TERM_LEN:
                index.setdefault(t.lower(), []).append((title, rel))
    return index


def linked_targets(text):
    """Lowercased note names this text already links to (path and heading stripped)."""
    names = re.findall(r"\[\[([^\]|#]+)", text)
    return {n.strip().split("/")[-1].lower() for n in names}


def link_text(title, matched):
    return f"[[{title}]]" if matched == title else f"[[{title}|{matched}]]"


def line_of(text, pos):
    start = text.rfind("\n", 0, pos) + 1
    end = text.find("\n", pos)
    return text.count("\n", 0, pos) + 1, text[start: end if end != -1 else len(text)].strip()


def scan(vault, note_rel):
    note_path = os.path.join(vault, note_rel)
    note_title = os.path.basename(note_rel)[:-3]
    skipped = set()
    index = build_index(vault, skipped)
    candidates = []

    # Outbound: other notes' terms in this note.
    text = read(note_path)
    terms = [t for t, hits in index.items() if any(p != note_rel for _, p in hits)]
    terms = [t for t in terms if t != note_title.lower()]
    seen = {t for t in linked_targets(text)}
    if terms:
        for m in term_regex(terms).finditer(masked(text)):
            hits = [h for h in index[m.group(1).lower()] if h[1] != note_rel]
            title = hits[0][0]
            if title.lower() in seen:
                continue
            seen.add(title.lower())
            line, ctx = line_of(text, m.start())
            candidates.append({
                "dir": "out", "file": note_rel, "offset": m.start(), "matched": m.group(1),
                "target": title, "ambiguous": sorted({p for _, p in hits}) if len(hits) > 1 else None,
                "line": line, "context": ctx, "replacement": link_text(title, m.group(1)),
            })

    # Inbound: this note's terms in other notes.
    own_terms = [note_title] + parse_aliases(text)
    own_terms = [t for t in own_terms if len(t) >= MIN_TERM_LEN]
    own_rx = term_regex(own_terms) if own_terms else None
    for path in walk(vault) if own_rx else []:
        rel = os.path.relpath(path, vault)
        if rel == note_rel:
            continue
        if is_dataless(path):
            skipped.add(rel)
            continue
        other = read(path)
        if note_title.lower() in linked_targets(other):
            continue
        m = own_rx.search(masked(other))
        if m:
            line, ctx = line_of(other, m.start())
            candidates.append({
                "dir": "in", "file": rel, "offset": m.start(), "matched": m.group(1),
                "target": note_title, "ambiguous": None,
                "line": line, "context": ctx, "replacement": link_text(note_title, m.group(1)),
            })

    for i, c in enumerate(candidates):
        c["id"] = i
    return {"note": note_rel, "skipped_dataless": len(skipped), "candidates": candidates}


def apply(vault, note_rel, ids):
    result = scan(vault, note_rel)
    chosen = [c for c in result["candidates"] if c["id"] in ids]
    missing = set(ids) - {c["id"] for c in chosen}
    if missing:
        sys.exit(f"unknown candidate ids: {sorted(missing)}")
    by_file = {}
    for c in chosen:
        by_file.setdefault(c["file"], []).append(c)
    for rel, cs in by_file.items():
        path = os.path.join(vault, rel)
        text = read(path)
        for c in sorted(cs, key=lambda c: c["offset"], reverse=True):
            end = c["offset"] + len(c["matched"])
            assert text[c["offset"]:end] == c["matched"], (rel, c)
            text = text[: c["offset"]] + c["replacement"] + text[end:]
        with open(path, "w", encoding="utf-8") as f:
            f.write(text)
    print(json.dumps([{k: c[k] for k in ("id", "dir", "file", "line", "matched", "replacement")}
                      for c in chosen], indent=1))


def main():
    if len(sys.argv) < 4 or sys.argv[1] not in ("scan", "apply"):
        sys.exit(__doc__)
    cmd, vault, note = sys.argv[1], os.path.abspath(sys.argv[2]), sys.argv[3]
    note_rel = os.path.relpath(os.path.join(vault, note), vault)
    if not os.path.isfile(os.path.join(vault, note_rel)):
        sys.exit(f"note not found: {note_rel}")
    if is_dataless(os.path.join(vault, note_rel)):
        sys.exit(f"note is an iCloud placeholder; download it first: {note_rel}")
    if cmd == "scan":
        print(json.dumps(scan(vault, note_rel), indent=1))
    else:
        apply(vault, note_rel, [int(i) for i in sys.argv[4:]])


if __name__ == "__main__":
    main()
