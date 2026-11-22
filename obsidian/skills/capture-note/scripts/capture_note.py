#!/usr/bin/env python3
"""Capture a URL into the Obsidian vault as a note that matches the vault's templates.

  capture_note.py inspect <vault> <url>
      -> JSON: existing note for this URL (if any), guessed type, extracted metadata.
  capture_note.py write <vault> <url> --type T [--title S] [--author NAME]... [--recommended-by NAME]...
      -> writes the note, prints its vault-relative path.

Types and where they land:
  article  Clippings/   categories [[Articles]], tags clippings + read-later, full content
  video    Clippings/   categories [[Videos]],   tags clippings + watch-later, content + transcript
  podcast  Clippings/   categories [[Podcasts]], tags clippings + read-later, full content
  book     References/  Books template, no content

Extraction uses Defuddle, the library inside Obsidian Web Clipper.
"""
import argparse
import json
import os
import re
import subprocess
import sys
from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit

DEFUDDLE = ["npx", "-y", "defuddle@0.19.6", "parse"]
SKIP_DIRS = {".obsidian", ".omc", ".claude", ".git", ".trash"}
TRACKING_PARAMS = re.compile(r"^(utm_|fbclid$|gclid$|mc_|ref$|ref_src$|s$|si$|t$)")
ILLEGAL_FILENAME = re.compile(r'[\\/:*?"<>|#^\[\]]')

TYPES = {
    "article": {"folder": "Clippings", "category": "Articles", "tag": "read-later"},
    "video": {"folder": "Clippings", "category": "Videos", "tag": "watch-later"},
    "podcast": {"folder": "Clippings", "category": "Podcasts", "tag": "read-later"},
    "book": {"folder": "References", "category": "Books", "tag": "read-later"},
}


def normalize_url(url):
    """Comparable form: no scheme, no www, no tracking params, no fragment, no trailing slash."""
    parts = urlsplit(url.strip())
    host = parts.netloc.lower().removeprefix("www.").removeprefix("m.")
    query = [(k, v) for k, v in parse_qsl(parts.query) if not TRACKING_PARAMS.match(k)]
    if host == "youtu.be":
        host, path, query = "youtube.com", "/watch", [("v", parts.path.strip("/"))]
    else:
        path = parts.path.rstrip("/")
    if host in ("twitter.com", "x.com"):
        host = "x.com"
    return urlunsplit(("", host, path, urlencode(sorted(query)), "")).lstrip("/")


def find_existing(vault, url):
    target = normalize_url(url)
    for root, dirs, files in os.walk(vault):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        for f in files:
            if not f.endswith(".md"):
                continue
            path = os.path.join(root, f)
            try:
                with open(path, encoding="utf-8") as fh:
                    head = fh.read(4000)
            except (OSError, UnicodeDecodeError):
                continue
            for m in re.finditer(r'^url:[ \t]*"?([^"\n]+?)"?[ \t]*$', head, re.M):
                if normalize_url(m.group(1)) == target:
                    return os.path.relpath(path, vault)
    return None


def guess_type(url):
    host = urlsplit(url).netloc.lower().removeprefix("www.")
    path = urlsplit(url).path
    if host in ("youtube.com", "youtu.be", "m.youtube.com", "vimeo.com"):
        return "video"
    if host in ("goodreads.com", "bookshop.org") or (host.startswith("amazon.") and "/dp/" in path):
        return "book"
    if host in ("podcasts.apple.com", "overcast.fm", "pca.st") or (host == "open.spotify.com" and "/episode/" in path):
        return "podcast"
    return "article"


def extract(url):
    proc = subprocess.run(DEFUDDLE + [url, "--json", "--markdown"], capture_output=True, text=True, timeout=180)
    if proc.returncode != 0:
        sys.exit(f"defuddle failed ({proc.returncode}): {proc.stderr.strip()[:500]}")
    try:
        data = json.loads(proc.stdout)
    except json.JSONDecodeError:
        sys.exit(f"defuddle returned non-JSON output: {proc.stdout[:300]}")
    return data


def x_handle(url):
    parts = urlsplit(url)
    if parts.netloc.lower().removeprefix("www.") in ("x.com", "twitter.com"):
        seg = parts.path.strip("/").split("/")
        if seg and seg[0]:
            return "@" + seg[0]
    return None


def default_authors(url, data):
    handle = x_handle(url)
    if handle:
        return [handle]
    author = (data.get("author") or "").strip()
    if not author:
        return []
    return [a.strip() for a in re.split(r",\s*|\s+and\s+|\s*&\s*", author) if a.strip()]


def safe_title(title):
    title = ILLEGAL_FILENAME.sub("", title)
    title = re.sub(r"\s+", " ", title).strip(" .")
    return title[:180]


def yaml_links(names):
    return "".join(f'\n  - "[[{n}]]"' for n in names)


def render(kind, url, authors, recommended, content):
    t = TYPES[kind]
    if kind == "book":
        return (
            "---\ntags:\n  - read-later\n"
            f'categories: "[[Books]]"\nurl: {url}\n'
            f"authors:{yaml_links(authors)}\n"
            f"recommended by:{yaml_links(recommended)}\n"
            "finished:\n---\n## Summary\n\n## Notes\n"
        )
    return (
        "---\ntags:\n"
        '  - "clippings"\n'
        f'  - "{t["tag"]}"\n'
        "categories:\n"
        f'  - "[[{t["category"]}]]"\n'
        f'url: "{url}"\n'
        f"authors:{yaml_links(authors)}\n"
        f'"recommended by":{yaml_links(recommended)}\n'
        "topics:\nrelated:\nprojects:\nareas:\nfinished:\n---\n"
        "## Summary\n\n#summarize-later\n\n## Content\n\n"
        f"{content.strip()}\n"
    )


def cmd_inspect(vault, url):
    existing = find_existing(vault, url)
    out = {"url": url, "existing": existing, "guessed_type": guess_type(url)}
    if not existing:
        data = extract(url)
        out.update({
            "title": data.get("title"),
            "safe_title": safe_title(data.get("title") or ""),
            "authors": default_authors(url, data),
            "site": data.get("site"),
            "published": data.get("published"),
            "description": data.get("description"),
            "word_count": data.get("wordCount"),
        })
    print(json.dumps(out, indent=1))


def cmd_write(vault, url, kind, title, authors, recommended):
    existing = find_existing(vault, url)
    if existing:
        sys.exit(f"already captured: {existing}")
    data = extract(url)
    title = safe_title(title or data.get("title") or "")
    if not title:
        sys.exit("no title extracted; pass --title")
    authors = authors or default_authors(url, data)
    content = "" if kind == "book" else (data.get("content") or "")
    if kind != "book" and not content.strip():
        sys.exit("defuddle extracted no content; the page may need a login or block scripted fetches")
    rel = os.path.join(TYPES[kind]["folder"], f"{title}.md")
    path = os.path.join(vault, rel)
    if os.path.exists(path):
        sys.exit(f"a note with this title already exists: {rel}")
    with open(path, "x", encoding="utf-8") as f:
        f.write(render(kind, url, authors, recommended, content))
    print(json.dumps({"path": rel, "type": kind, "authors": authors, "chars": len(content)}))


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)
    i = sub.add_parser("inspect")
    i.add_argument("vault")
    i.add_argument("url")
    w = sub.add_parser("write")
    w.add_argument("vault")
    w.add_argument("url")
    w.add_argument("--type", required=True, choices=sorted(TYPES))
    w.add_argument("--title")
    w.add_argument("--author", action="append", default=[])
    w.add_argument("--recommended-by", action="append", default=[])
    a = p.parse_args()
    vault = os.path.abspath(a.vault)
    if not os.path.isdir(os.path.join(vault, ".obsidian")):
        sys.exit(f"not an Obsidian vault (no .obsidian/): {vault}")
    if a.cmd == "inspect":
        cmd_inspect(vault, a.url)
    else:
        cmd_write(vault, a.url, a.type, a.title, a.author, a.recommended_by)


if __name__ == "__main__":
    main()
