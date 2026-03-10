---
name: product-requirements-doc
description: This skill should be used when the user asks to "write a PRD", "create a PRD" "define requirements", "spec out a feature", "write a spec", "product requirements document" "feature specification", "requirements doc", "write requirements for", or mentions needing a PRD for a new feature. Guides structured discovery and produces a complete product requirements document as markdown."
---

# Product Requirements Document (PRD) Creator

## Purpose

Create clear, actionable product requirements documents for new features that:

- Align stakeholders on what is being built, why, and for whom.
- Define measurable success criteria before implementation begins.
- Capture scope boundaries to prevent scope creep.
- Serve as a durable reference throughout development and launch.

## Applicable Scenarios

- New feature additions to an existing product.
- Significant enhancements to existing functionality.
- Features requiring cross-team coordination or stakeholder alignment.
- Any work where requirements need to be documented before implementation.

---

## Workflow

### Phase 1: Discovery

Before writing the PRD, gather context through targeted questions. Prioritize the most critical unknowns first:

1. **Problem**: What specific user problem or business need does this feature address? What evidence exists (user feedback, metrics, support tickets)?
2. **Users**: Who are the target users? What are their current workarounds?
3. **Success**: How will success be measured? What metrics should move?
4. **Scope**: What is explicitly out of scope? What adjacent problems should be deferred?
5. **Constraints**: Are there technical, timeline, regulatory, or resource constraints?

Limit discovery to 3-5 focused questions per round. Avoid overwhelming with all questions at once.

### Phase 2: Research

When working within an existing codebase:

- Examine relevant code, APIs, and data models that the feature touches.
- Identify existing patterns and conventions to align with.
- Review existing test coverage around the affected area.
- Check for related feature flags, configuration, or environment-specific behavior.
- Surface technical constraints or dependencies early.
- Note integration points with other systems or features.
- Review recent bug reports, support tickets, or changelog entries for related context.

### Phase 3: Writing

Produce the PRD using the template structure from `references/prd-template.md` (includes section-by-section guidance with good/poor examples). For a completed example, see `examples/example-prd.md`. Key principles:

- **Clarity over completeness**: Omit sections that genuinely do not apply, but note why.
- **Specificity over vagueness**: Replace "fast" with "< 200ms p95 latency". Replace "easy to use" with concrete interaction descriptions.
- **User-centric language**: Frame requirements from the user's perspective, not implementation details.
- **Testable requirements**: Every functional requirement should have a clear pass/fail condition.

### Phase 4: Review

After drafting, verify completeness against this checklist:

- [ ] Problem statement is specific and evidence-backed
- [ ] Success metrics are measurable and time-bound
- [ ] User stories cover primary and edge-case flows
- [ ] Functional requirements are testable
- [ ] Scope boundaries are explicit (in-scope and out-of-scope)
- [ ] Dependencies and risks are identified with mitigations
- [ ] Open questions are captured for follow-up

---

## Output Format

Save the PRD as a markdown file in the current project:

- **Filename**: `prd-<feature-slug>.md` (e.g., `prd-user-notifications.md`)
- **Location**: Project root or a `docs/` directory if one exists.
- **Front matter**: Include title, author, date, and status at the top.

---

## Writing Guidance

### Requirements Quality

Write requirements that are **SMART**:

| Attribute   | Meaning                                         |
| ----------- | ----------------------------------------------- |
| Specific    | One clear behavior per requirement              |
| Measurable  | Quantifiable acceptance criteria                |
| Achievable  | Feasible within known constraints               |
| Relevant    | Directly tied to the problem statement          |
| Testable    | Clear pass/fail verification possible           |

### Pitfalls to Avoid

- **Solutioning in requirements**: Describe *what* the system must do, not *how* to build it. Implementation details belong in technical design docs.
- **Ambiguous language**: Avoid "should", "might", "could". Use "must" for mandatory requirements, "may" for optional ones.
- **Missing edge cases**: Explicitly address error states, empty states, permission boundaries, and degraded conditions.
- **Unstated assumptions**: Surface assumptions as constraints or open questions.

### Scope Management

Define scope with two explicit lists:

- **In scope**: Specific capabilities this PRD covers.
- **Out of scope**: Related work explicitly deferred, with brief rationale.

This prevents both scope creep and ambiguity about what "done" means.

---

## Bundled Resources

- **`references/prd-template.md`** - Complete PRD template with section-by-section guidance and good/poor examples.
- **`examples/example-prd.md`** - Fully completed example PRD demonstrating expected quality and tone.
