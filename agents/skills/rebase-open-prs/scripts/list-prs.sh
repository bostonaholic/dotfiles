#!/usr/bin/env bash
set -euo pipefail

# list-prs.sh — list open PRs that are candidates for rebasing onto their base.
#
# Usage:
#   list-prs.sh [--author <user|@me>] [--include-forks] [--skip-drafts] [--limit N]
#
# Defaults: drafts are INCLUDED (they are open PRs), forks are EXCLUDED
# (contributor fork branches usually cannot be pushed to).
#
# Output (stdout): JSON array. Each element:
#   { number, title, headRefName, baseRefName, isDraft, isCrossRepository,
#     mergeStateStatus, author, url, rebaseable, skipReason }
# Run filtered downstream on `.rebaseable == true`. Diagnostics go to stderr.

include_forks=false
skip_drafts=false
author=""
limit=200

while [ $# -gt 0 ]; do
  case "$1" in
    --include-forks) include_forks=true; shift ;;
    --skip-drafts)   skip_drafts=true;   shift ;;
    --author)        author="$2";        shift 2 ;;
    --limit)         limit="$2";         shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

fields="number,title,headRefName,baseRefName,isDraft,isCrossRepository,mergeStateStatus,author,url"
args=(pr list --state open --limit "$limit" --json "$fields")
[ -n "$author" ] && args+=(--author "$author")

raw=$(gh "${args[@]}")

result=$(echo "$raw" | jq \
  --argjson incForks "$include_forks" \
  --argjson skipDrafts "$skip_drafts" '
  map(
    (if   .isCrossRepository and ($incForks   | not) then "fork (cannot push to contributor branch)"
     elif .isDraft           and ($skipDrafts)       then "draft (skipped by request)"
     else null end) as $skip
    | .author = (.author.login // .author)
    | . + { rebaseable: ($skip == null), skipReason: $skip }
  )')

# Human-readable summary to stderr.
total=$(echo "$result" | jq 'length')
ok=$(echo "$result" | jq '[.[] | select(.rebaseable)] | length')
echo "Found $total open PR(s); $ok rebaseable, $((total - ok)) skipped." >&2

echo "$result"
