# PRD Template

Copy this template and fill in each section. Remove guidance text (in parentheses) before finalizing.

---

```markdown
# PRD: [Feature Name]

| Field        | Value                          |
| ------------ | ------------------------------ |
| Author       | [Name]                         |
| Date         | [YYYY-MM-DD]                   |
| Status       | Draft / In Review / Approved   |
| Stakeholders | [List key stakeholders]        |

---

## 1. Problem Statement

(Describe the specific user problem or business need this feature addresses.
Include evidence: user feedback, support tickets, metrics, or competitive gaps.
Keep to 2-3 paragraphs maximum.)

### Current State

(How do users handle this today? What are the pain points and workarounds?)

### Evidence

(What data supports this problem? Quantify where possible.)

---

## 2. Goals and Success Metrics

### Goals

(What does success look like? Be specific and measurable.)

- **Primary goal**: [Specific, measurable outcome]
- **Secondary goal**: [Additional measurable outcome]

### Success Metrics

| Metric           | Current Baseline | Target        | Measurement Method |
| ---------------- | ---------------- | ------------- | ------------------ |
| [Metric name]    | [Current value]  | [Target value]| [How to measure]   |

### Non-Goals

(Explicitly state what this feature is NOT trying to achieve.)

---

## 3. User Stories

(Describe who benefits and how. Use the format: "As a [user type], I want
[capability] so that [benefit].")

### Primary User Story

> As a [user type], I want [capability] so that [benefit].

**Acceptance criteria:**

- [ ] [Specific, testable criterion]
- [ ] [Specific, testable criterion]

### Additional User Stories

> As a [user type], I want [capability] so that [benefit].

**Acceptance criteria:**

- [ ] [Specific, testable criterion]

---

## 4. Functional Requirements

(List what the system must do. Each requirement should be independently
testable. Use "must" for mandatory, "may" for optional.)

### Core Requirements

| ID    | Requirement                              | Priority    |
| ----- | ---------------------------------------- | ----------- |
| FR-1  | The system must [specific behavior]      | Must have   |
| FR-2  | The system must [specific behavior]      | Must have   |
| FR-3  | The system may [specific behavior]       | Nice to have|

### Edge Cases and Error Handling

| ID    | Scenario                                 | Expected Behavior       |
| ----- | ---------------------------------------- | ----------------------- |
| EC-1  | [Edge case description]                  | [How system responds]   |
| EC-2  | [Error condition]                        | [Error handling behavior]|

---

## 5. Non-Functional Requirements

(Performance, security, accessibility, and other quality attributes.)

| Category        | Requirement                                           |
| --------------- | ----------------------------------------------------- |
| Performance     | [e.g., Response time < 200ms at p95]                  |
| Availability    | [e.g., 99.9% uptime]                                 |
| Security        | [e.g., All data encrypted at rest and in transit]     |
| Accessibility   | [e.g., WCAG 2.1 AA compliance]                       |
| Scalability     | [e.g., Support 10x current load without degradation]  |
| Data            | [e.g., Retain data for 90 days, GDPR compliant]      |

---

## 6. Scope

### In Scope

- [Specific capability or behavior included]
- [Specific capability or behavior included]

### Out of Scope

- [Deferred item] — Rationale: [Why deferred]
- [Deferred item] — Rationale: [Why deferred]

---

## 7. Solution Overview

(High-level approach. This is NOT a technical design — keep it conceptual.
Describe the user experience and key interactions, not implementation.)

### User Flow

(Describe the primary user journey through the feature, step by step.)

1. User [action]
2. System [response]
3. User [action]

### Key Interactions

(Describe important UI states, transitions, or behaviors.)

---

## 8. Dependencies and Risks

### Dependencies

| Dependency               | Owner        | Status       | Impact if Delayed    |
| ------------------------ | ------------ | ------------ | -------------------- |
| [External system/team]   | [Who owns it]| [Status]    | [What happens]       |

### Risks

| Risk                     | Likelihood   | Impact       | Mitigation           |
| ------------------------ | ------------ | ------------ | -------------------- |
| [Risk description]       | Low/Med/High | Low/Med/High | [Mitigation plan]    |

---

## 9. Timeline and Milestones

(High-level phases. Detailed scheduling belongs in project management tools.)

| Milestone                | Target Date  | Deliverable              |
| ------------------------ | ------------ | ------------------------ |
| Requirements approved    | [Date]       | This PRD signed off      |
| Design complete          | [Date]       | Technical design doc     |
| Implementation complete  | [Date]       | Feature ready for QA     |
| Launch                   | [Date]       | Feature available to users|

---

## 10. Open Questions

(Capture unresolved items. Assign an owner and target date for resolution.)

| Question                                    | Owner        | Target Date  |
| ------------------------------------------- | ------------ | ------------ |
| [Unresolved question]                       | [Who]        | [When]       |
```

---

## Section-by-Section Guidance

### Problem Statement

A strong problem statement is evidence-backed and specific:

**Good:**
> Users abandon the checkout flow at the payment step at a rate of 34%
> (compared to industry average of 22%). Exit surveys indicate confusion
> about shipping cost calculations, which are not shown until the final step.

**Poor:**
> Users don't like the checkout experience. We need to make it better.

### Goals and Success Metrics

Metrics must be measurable and baseline-referenced:

**Good:**
> Reduce checkout abandonment at the payment step from 34% to 25% within
> 60 days of launch, measured via analytics funnel.

**Poor:**
> Improve the checkout experience.

### Functional Requirements

Each requirement should be independently testable with one clear behavior:

**Good:**
> FR-1: The system must display estimated shipping cost on the cart page
> before the user enters the checkout flow.

**Poor:**
> The system should show shipping information somewhere in the flow.

### User Stories

Include acceptance criteria that map to testable conditions:

**Good:**
> As a shopper, I want to see estimated shipping cost on my cart page so
> that I can make a purchase decision before starting checkout.
>
> Acceptance criteria:
>
> - Shipping estimate appears within 2 seconds of cart page load
> - Estimate updates when cart items or delivery address change
> - "Unable to estimate" message shown when address is incomplete

**Poor:**
> As a user, I want better shipping info.

### Non-Functional Requirements

Quantify expectations. Avoid subjective terms:

**Good:**
> Cart page must load in < 1.5 seconds at p95 with shipping estimate visible.

**Poor:**
> The page should load fast.
