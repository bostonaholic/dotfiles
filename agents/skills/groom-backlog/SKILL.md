---
name: groom-backlog
description: Groom and prioritize a project backlog — verify each candidate issue's claims against the current codebase, pick the most important N, rewrite them to a ready-to-work standard (Problem/Goals/Decisions/Outcomes/Verification), move them to Ready on the board, and close obsolete issues. Use when asked to "groom the backlog", "triage the backlog", "prioritize issues", "move issues to ready", or "what should we work on next".
---

# Groom Backlog

Turn a raw backlog into a small set of verified, decision-complete, ready-to-work
issues. The core discipline: **never promote an issue whose claims you haven't
checked against the current code.** Backlogs rot — files move, PRs land, repros
stop reproducing. Grooming without verification ships stale work to the top of
the queue.

## Inputs

- Optional: how many issues to ready (default 4) and any focus area.
- The tracker. Discover it before asking: check the project's CLAUDE.md /
  AGENTS.md for a "Work Tracking" section, then `gh repo view` for the
  repo, then `gh project list --owner <owner>`. Ask only if genuinely ambiguous.

## Workflow

Seed a todo per numbered step; mark each complete as you go.

### 1. Inventory the backlog

Fetch every backlog item WITH its full body in one batch — titles alone are not
groomable. For GitHub Projects:

```bash
gh project item-list <N> --owner <owner> --format json --limit 100   # ids + statuses
for n in <backlog issue numbers>; do gh issue view $n --repo <owner>/<repo> \
  --json number,title,labels,body,state,url; done
```

Check the returned count — if it equals the `--limit`, raise it or paginate;
silently dropped items never get groomed.

For beads: `bd list --json` returns every issue with its body in one call.

Large output: persist to a file and Read it back rather than re-fetching.

### 2. Verify claims against reality (the load-bearing step)

For each plausible candidate, check its factual claims against the current
codebase before ranking it:

- Files/paths it names still exist (`ls`, Glob).
- Line-level claims still hold (`grep` the quoted text — it may have been fixed
  or moved).
- Referenced PRs/commits landed or didn't; referenced bugs still reproduce
  (run the free/cheap repro — e.g. the test suite — if the issue claims failures).
- Counts it cites ("~50 files reference X") are still roughly right.

Outcomes per issue: **claims hold** (candidate), **partially stale** (groom with
corrections), or **premise evaporated** (flag for closure, not grooming). Expect
to find at least one of the third kind in any backlog older than a month.

### 3. Prioritize

Ranking heuristic, in order:

1. **Bugs and contradictions in shipped behavior** — especially docs/config that
   give users or agents conflicting instructions.
2. **Reliability of the project's own verification harness** (flaky tests/evals,
   broken CI) — everything else is judged through it.
3. **Well-specified, high-leverage improvements** — prefer issues whose open
   questions can be resolved *during grooming* over ones needing real design work.
4. **Strategic/research items** only when they unblock several others.

Tiebreaker: smaller verified scope beats bigger promised impact.

### 4. Propose the slate — approval gate

Present a table: issue, one-line why-now, and the *verified* facts supporting it.
List separately any premise-evaporated issues recommended for closure, with
evidence. **AskUserQuestion before mutating anything** — offer the slate, the
strongest runner-up swaps, and the closures as separate decisions.

### 5. Groom each approved body

Rewrite the issue body (`gh issue edit N --body-file <tmp>`; always a temp file,
never inline quoting) into this structure, preserving original evidence, links,
and any provenance/migration footers:

- **Problem Statement** — what is wrong/missing, with verified file:line
  references and a "verified `<date>`" stamp on each checked claim.
- **Goals** — what done looks like, outcome-framed.
- **Decisions** — resolve the issue's open questions with a recorded choice and
  one-line rationale each. An issue with open design questions is not Ready;
  if a question genuinely can't be resolved at grooming time, say so and route
  it to a design step instead of promoting it.
- **Scope of Change** — files/areas touched (only when known; don't invent).
- **Outcomes** — observable effects after the work lands.
- **Verification Steps** — numbered, runnable checks (commands, greps, test
  invocations, smoke runs) that an implementer can execute to prove completion.

### 6. Move cards to Ready

GitHub Projects needs three IDs once:

```bash
gh project view <N> --owner <owner> --format json --jq '.id'
gh project field-list <N> --owner <owner> --format json \
  --jq '.fields[] | select(.name=="Status") | {id, options}'
gh project item-edit --id <item-id> --project-id <proj> \
  --field-id <status-field> --single-select-option-id <ready-option>
```

Beads has no Ready column — readiness is derived (open + unblocked). Promote
by setting priority (`bd update <id> --priority <P> --json`) and resolving or
removing the blocking dependencies that keep it out of `bd ready`.

### 7. Close obsolete issues

`gh issue close N --reason "not planned" --comment "<evidence>"` — or for
beads, `bd close <id> --reason "<evidence>" --json`. The evidence must say
what changed, when, and what proves the premise is gone (e.g. "the failing
tests this describes were deleted in PR #31; suite now passes 245/0").
Move the card to Done.

### 8. Verify and report

Re-list the board and confirm every intended status change took. End with a
summary table — issue, action taken, why — including the closures. State
confidence per claim if the project's conventions ask for it.

## Hard rules

- No mutation before the step-4 approval gate.
- Never delete or overwrite original issue evidence; restructure around it.
- Decisions recorded during grooming are recommendations the implementer may
  revisit — label them as decisions with rationale, not silent rewrites of intent.
- If the project tracks work somewhere else (Linear, Jira, etc.), adapt
  steps 1/6/7 to that tracker's CLI; the verify→prioritize→groom→gate spine is
  tracker-agnostic.
