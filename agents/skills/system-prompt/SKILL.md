---
name: system-prompt
description: Use when writing, reviewing, or improving system prompts for AI tools, agents, chatbots, or LLM-powered products. Trigger phrases include "write a system prompt", "create a system prompt", "system prompt for X", "improve this prompt", "review my prompt", "prompt engineering".
---

# System Prompt Engineering

## The Rule

**Structure beats cleverness. Concrete examples beat abstract instructions.**

A system prompt is a contract between you and the model. Every line must earn
its place. If you can't test it, cut it.

**NEVER use emdashes (—) in prompts you write.** Use commas, periods, colons,
semicolons, or parentheses instead. Rewrite any sentence that seems to need an
emdash.

## Universal Section Order

Models weight earlier content more heavily. Follow this order:

```text
1. Identity & Role           (1-5 lines)
2. Mission / Stop Criteria   (2-10 lines)
3. Communication Style       (5-20 lines)
4. Core Workflow              (10-50 lines)
5. Tool Usage Rules           (varies)
6. Domain-Specific Rules      (code style, etc.)
7. Safety & Constraints       (NEVER/ALWAYS)
8. Edge Cases & Error Handling
9. Examples                   (few-shot, 3-10)
10. Runtime Context           (injected dynamically)
```

## Process

### Step 1 — Gather Requirements

Before writing anything, ask the user:

1. **What is this AI doing?** (role, product, tool)
2. **Who is the user?** (developer, end-user, internal team)
3. **What tools/capabilities does the AI have?** (code execution, web search, file editing, API calls)
4. **What does "done" look like?** (completion criteria)
5. **What must never happen?** (safety constraints, destructive actions)
6. **What's the expected output format?** (prose, code, structured data, conversational)

If the user has an existing prompt, read it first before suggesting changes.

### Step 2 — Write Each Section

Follow the guidance below for each section. Skip sections that don't apply.

### Step 3 — Add Examples

This is the highest-ROI step. Add 3-10 concrete examples showing:

- Expected response length and tone
- Tool call decisions (when to call vs. answer directly)
- Edge cases and error handling
- Bad-to-good pairs (counter-examples)

### Step 4 — Review Against Checklist

Run through the quality checklist at the bottom before delivering.

---

## Section Guidance

### 1. Identity & Role

Open with "You are..." — every production prompt does this. It frames
everything that follows.

**Rules:**
- Name the specific role, not "AI assistant"
- Set the competence level ("expert", "senior engineer", "specialist in X")
- Anchor the relationship ("pair programming with the user", "helping a team of...")
- Keep it to 1-5 lines

**Good:**
```text
You are a senior backend engineer specializing in distributed systems.
You pair-program with the user to design and implement reliable services.
```

**Bad:**
```text
I am an AI assistant designed to help users with a wide range of tasks
including but not limited to programming, writing, and analysis...
```

### 2. Mission / Stop Criteria

Define when the AI's job is done. Without this, models stop early and ask
for permission.

**Rules:**
- State explicit completion criteria
- Bias toward action over confirmation
- Ban over-confirming ("let me know if that's okay")

**Good:**
```text
Keep going until the user's request is fully resolved. Do not stop to ask
for permission unless you are genuinely blocked. State assumptions and proceed.
```

### 3. Communication Style

Every top prompt enforces brevity. Models default to verbose.

**Rules:**
- Cap response length explicitly ("fewer than 4 lines" is more enforceable than "be concise")
- Ban filler, preamble, and postamble
- Ban emojis unless requested
- Use backticks for code references
- Separate code verbosity from prose verbosity (code should be readable; explanations should be brief)

**Do NOT include:**
- "Be helpful and friendly" — default behavior, wastes tokens
- Generic formatting rules — only include specific, testable requirements

### 4. Core Workflow

Define the process, not just the goal. The universal pattern across
production prompts is: **Read, Plan, Execute, Verify.**

**Rules:**
- Define phase gates ("before starting edits, reconcile the plan")
- Define mode transitions ("default to discussion; only implement when action words are used")
- Include a verification step ("run tests before submitting")
- Include status update rules if multi-step

**Example structure:**
```text
1. Discovery — Read relevant files, understand current state
2. Plan — Create a structured plan, get alignment
3. Execute — Implement changes, one logical step at a time
4. Verify — Run tests, lint, confirm the change works
```

### 5. Tool Usage Rules

Models default to sequential tool calls. You must actively override this.

**Rules to always include:**
- "Default to parallel tool calls when independent"
- "Prefer specialized tools over shell commands" (with specifics)
- "Read before edit — never edit a file without reading it first"
- "Set loop/retry limits" (typically 3 attempts before escalating)
- "Don't mention tool names to the user" — describe actions naturally

**Example:**
```text
CRITICAL: Call all independent tools concurrently. Do not serialize.

Prefer specialized tools:
- Use Read instead of cat/head/tail
- Use Search instead of grep/find
- Use Edit instead of sed/awk

NEVER edit a file you haven't read in this conversation.
If an approach fails 3 times, stop and explain the blocker.
```

### 6. Domain-Specific Rules

Separate domain rules (code style, naming conventions, architectural patterns)
into their own section. Use concrete bad-to-good pairs.

**Example:**
```text
## Code Style

Naming:
- BAD:  genYmdStr, handleClick2, processData
- GOOD: generateDateString, handlePaymentClick, validateUserInput

Functions: single responsibility, <30 lines, pure when possible.
Comments: explain WHY, not WHAT. No commented-out code.
```

### 7. Safety & Constraints

Use severity-layered keywords. Models learn to weight all-caps heavily.

**Severity levels:**
```text
CRITICAL: ...  — Absolute, no exceptions
IMPORTANT: ... — Strong default, rare exceptions
NEVER: ...     — Absolute prohibition
ALWAYS: ...    — Absolute requirement
```

**What to constrain:**
- Security (secrets, credentials, injection)
- Destructive operations (deletion, force-push, production changes)
- Scope creep (don't add unrequested features)
- Assumptions (don't guess; ask or verify)

**Rules:**
- Repeat truly critical constraints (models respond to repetition)
- Don't over-constrain — too many rules dilute the important ones
- Don't constrain default behavior (wastes tokens)

### 8. Edge Cases & Error Handling

Define what to do when things go wrong. Use concrete scenarios, not
nested conditionals.

**Example:**
```text
If a test fails after your edit:
1. Read the error output carefully
2. Check if the test expectation needs updating (intentional change)
3. If the production code is wrong, fix it
4. If you can't determine root cause in 3 attempts, explain what you tried

If the user's request is ambiguous:
- State your interpretation and proceed
- Don't ask 5 clarifying questions — make a reasonable choice
```

### 9. Examples

Few-shot examples are the highest-ROI technique. Use XML tags for structure.

**Show these:**
- Response length and tone
- Tool call decisions
- Multi-step workflows
- Error handling
- Counter-examples (what NOT to do)

**Format:**
```xml
<example>
User: How do I add a new API endpoint?
Assistant: Create a route handler in `app/api/your-endpoint/route.ts`:
[3-4 lines of code]
Then add the corresponding type in `lib/types.ts`.
</example>

<bad-example>
User: How do I add a new API endpoint?
Assistant: Great question! There are several ways to add an API endpoint
in Next.js. Let me walk you through the options...
[200 words of preamble before getting to the answer]
</bad-example>
```

### 10. Runtime Context

Reserve a section for dynamically injected context (current file, git status,
environment, user preferences). Don't hardcode what should be dynamic.

```text
## Current Context
- Working directory: {{cwd}}
- Current file: {{active_file}}
- Git branch: {{branch}}
- User preferences: {{preferences}}
```

---

## Advanced Techniques

### Think-Before-Acting Triggers

Define explicit moments where the model must pause and reason before acting.
High-stakes operations benefit from forced deliberation.

```text
Before these actions, stop and reason in a <think> block:
- Any git operation that rewrites history
- Deleting files or database records
- Transitioning from reading code to writing code
- Before claiming a task is complete
```

### Discussion-First vs Action-First Modes

If the tool supports both exploration and execution, make the default mode
explicit and define transition criteria.

```text
Default to discussion mode. Only proceed to implementation when the user
uses action words: "implement", "build", "create", "fix", "change".

When in discussion mode: explain options, ask questions, suggest approaches.
When in action mode: implement directly, verify, report results.
```

### Status Update Protocol

For multi-step workflows, define how progress is communicated.

```text
After each major step, report:
- What was completed (past tense)
- What's next (present tense)
- Any blockers or decisions needed

Do NOT: add headings like "Update:", repeat context the user already knows,
or summarize what you're about to do before doing it.
```

---

## Anti-Patterns to Flag

When reviewing an existing prompt, flag these:

| Anti-Pattern | Problem | Fix |
|-------------|---------|-----|
| Capability laundry list | Wastes tokens, model knows what it can do | Cut entirely |
| "Be helpful and friendly" | Default behavior | Cut entirely |
| Marketing language | Model doesn't care | Cut entirely |
| Defensive disclaimers | Undermines confidence | Cut entirely |
| Nested conditionals for rare cases | Confuses the model | Use examples instead |
| Vague personality directives | Not testable | Use concrete caps and rules |
| No examples | Lowest-ROI omission | Add 3-10 examples |
| Sequential tool instructions | Models default to sequential anyway | Explicitly mandate parallel |
| Rules about default behavior | Wastes tokens reinforcing what's already true | Cut entirely |

---

## Quality Checklist

Before delivering, verify the prompt has:

- [ ] Clear identity in 1-5 lines
- [ ] Explicit completion criteria (when to stop)
- [ ] Concrete response length caps (number, not adjective)
- [ ] Parallelization mandate for tool calls (if applicable)
- [ ] "Read before edit" rule (if applicable)
- [ ] Tool preference hierarchy (if applicable)
- [ ] Loop/retry limits (typically 3)
- [ ] NEVER/ALWAYS constraints for security-critical rules
- [ ] 3-10 few-shot examples with counter-examples
- [ ] Multi-step workflow with phase gates (if agentic)
- [ ] Context efficiency rules (don't re-read provided context)
- [ ] Domain-specific rules with concrete examples
- [ ] Error escalation path
- [ ] Dynamic runtime context section (if applicable)

**Cut if present:**
- [ ] No capability lists
- [ ] No generic personality directives
- [ ] No marketing copy
- [ ] No defensive disclaimers
- [ ] No rules about default behavior
