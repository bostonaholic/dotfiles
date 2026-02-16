# PRD: Inline Shipping Estimate on Cart Page

| Field        | Value                                    |
| ------------ | ---------------------------------------- |
| Author       | Jane Chen                                |
| Date         | 2025-03-15                               |
| Status       | Approved                                 |
| Stakeholders | Product (Jane), Engineering (Dev Team B), Design (Alex), Logistics (Sam) |

---

## 1. Problem Statement

Users abandon the checkout flow at the payment step at a rate of 34%, compared to an industry average of 22%. Exit surveys (n=1,247, Q4 2024) indicate that 61% of abandoning users cite "unexpected shipping costs" as their primary reason for leaving.

### Current State

Shipping cost is calculated and displayed only on the final payment confirmation page. Users add items to their cart, proceed through address entry and payment details, and only then discover the shipping cost. This late reveal creates a trust gap and drives abandonment.

### Evidence

- **Checkout funnel analytics (Q4 2024)**: 34% drop-off at payment step, 12 percentage points above industry benchmark.
- **Exit survey (n=1,247)**: 61% cite unexpected shipping costs.
- **Support tickets**: 142 shipping-related complaints in Q4 2024, up 23% quarter-over-quarter.
- **Competitor analysis**: 4 of 5 direct competitors display shipping estimates on the cart page.

---

## 2. Goals and Success Metrics

### Goals

- **Primary goal**: Reduce checkout abandonment at the payment step from 34% to 25% within 60 days of launch.
- **Secondary goal**: Reduce shipping-related support tickets by 40% within 90 days of launch.

### Success Metrics

| Metric                         | Current Baseline | Target   | Measurement Method             |
| ------------------------------ | ---------------- | -------- | ------------------------------ |
| Payment-step abandonment rate  | 34%              | 25%      | Analytics funnel (Mixpanel)    |
| Shipping support tickets/month | 47               | 28       | Zendesk tag: "shipping-cost"   |
| Cart-to-purchase conversion    | 18%              | 22%      | Analytics funnel (Mixpanel)    |
| Cart page load time (p95)      | 1.2s             | < 1.5s   | Datadog RUM                    |

### Non-Goals

- Changing actual shipping rates or carrier contracts.
- Supporting real-time carrier rate lookups (deferred to Phase 2).
- Redesigning the full checkout flow.

---

## 3. User Stories

### Primary User Story

> As a shopper with items in my cart, I want to see the estimated shipping cost before starting checkout so that I can make a purchase decision without surprises.

**Acceptance criteria:**

- [ ] Shipping estimate appears on the cart page within 2 seconds of page load
- [ ] Estimate updates within 1 second when cart items change (add, remove, quantity)
- [ ] Estimate reflects the user's saved delivery address, or a default region if no address is saved
- [ ] Estimate displays a range (e.g., "$4.99 - $7.99") when the exact cost cannot be determined

### Additional User Stories

> As a shopper without a saved address, I want to enter my zip code on the cart page so that I can get a shipping estimate specific to my location.

**Acceptance criteria:**

- [ ] A zip code input field appears when no saved address exists
- [ ] Estimate updates within 1 second of valid zip code entry
- [ ] Invalid zip codes display an inline validation error without page reload

> As a returning customer with a saved address, I want my shipping estimate to use my default address automatically so that I see an accurate estimate without extra steps.

**Acceptance criteria:**

- [ ] Saved default address is used automatically for the estimate
- [ ] A "Change location" link allows overriding with a different zip code

---

## 4. Functional Requirements

### Core Requirements

| ID   | Requirement                                                                               | Priority     |
| ---- | ----------------------------------------------------------------------------------------- | ------------ |
| FR-1 | The system must display an estimated shipping cost on the cart page                        | Must have    |
| FR-2 | The estimate must update when cart contents change (add, remove, quantity adjustment)      | Must have    |
| FR-3 | The system must accept a zip code input for users without a saved address                  | Must have    |
| FR-4 | The system must use the saved default address for authenticated users with an address      | Must have    |
| FR-5 | The estimate must display as a range when exact cost cannot be determined                  | Must have    |
| FR-6 | The system must display "Free shipping" when the cart qualifies for free shipping          | Must have    |
| FR-7 | The system may show a "Add $X more for free shipping" prompt when close to the threshold   | Nice to have |

### Edge Cases and Error Handling

| ID   | Scenario                                        | Expected Behavior                                           |
| ---- | ----------------------------------------------- | ----------------------------------------------------------- |
| EC-1 | Shipping estimation service is unavailable       | Display "Shipping calculated at checkout" with no estimate  |
| EC-2 | Cart contains only digital/non-shippable items   | Display "No shipping required" instead of an estimate       |
| EC-3 | Invalid zip code entered                         | Inline error: "Enter a valid 5-digit US zip code"          |
| EC-4 | Cart is empty                                    | No shipping estimate section displayed                      |
| EC-5 | Items restricted to certain regions              | Display "Shipping unavailable to this location" for those items |

---

## 5. Non-Functional Requirements

| Category      | Requirement                                                               |
| ------------- | ------------------------------------------------------------------------- |
| Performance   | Cart page load time must remain < 1.5s at p95 with estimate visible      |
| Performance   | Estimate recalculation must complete within 1 second of input change      |
| Availability  | Shipping estimation must degrade gracefully (EC-1) without blocking cart  |
| Security      | Zip code input must be sanitized; no PII stored from anonymous estimates  |
| Accessibility | Estimate display and zip code input must meet WCAG 2.1 AA                |
| Accessibility | Estimate updates must be announced to screen readers via ARIA live region |

---

## 6. Scope

### In Scope

- Displaying a shipping cost estimate on the cart page.
- Zip code input for anonymous/addressless users.
- Automatic address detection for authenticated users.
- Graceful degradation when the estimation service is unavailable.

### Out of Scope

- Real-time carrier API integration (Phase 2) -- current estimates use internal rate tables.
- International shipping estimates -- limited to US domestic for initial launch.
- Checkout flow redesign -- only the cart page is modified.
- Shipping rate changes -- rates themselves are unchanged.

---

## 7. Solution Overview

### User Flow

1. User navigates to cart page with items.
2. System checks for a saved delivery address (authenticated users).
3. If address exists: system displays shipping estimate using the default address.
4. If no address: system displays a zip code input field with placeholder text.
5. User enters zip code (if needed).
6. System calculates and displays the estimated shipping cost or range.
7. User modifies cart contents.
8. System recalculates and updates the estimate.

### Key Interactions

- **Estimate display**: Appears in a dedicated section below the cart total, above the "Proceed to Checkout" button.
- **Loading state**: Skeleton placeholder while estimate calculates.
- **Free shipping threshold**: Progress indicator showing how close the cart is to free shipping (FR-7, nice to have).
- **Error state**: Muted text replacing the estimate when the service is unavailable.

---

## 8. Dependencies and Risks

### Dependencies

| Dependency                | Owner         | Status     | Impact if Delayed                           |
| ------------------------- | ------------- | ---------- | ------------------------------------------- |
| Shipping rate table API   | Logistics     | Available  | Cannot calculate estimates without it        |
| User address service      | Auth Team     | Available  | Fallback to zip code input for all users     |
| Cart service update event | Platform Team | In progress| Estimate won't auto-update on cart changes   |

### Risks

| Risk                                        | Likelihood | Impact | Mitigation                                        |
| ------------------------------------------- | ---------- | ------ | ------------------------------------------------- |
| Estimate inaccuracy erodes trust            | Medium     | High   | Display as range; add "final cost at checkout" disclaimer |
| Rate table API latency impacts cart load    | Low        | High   | Async loading with skeleton; timeout at 2s        |
| Increased cart page complexity impacts performance | Low  | Medium | Performance budget enforced; lazy-load estimate module |

---

## 9. Timeline and Milestones

| Milestone               | Target Date | Deliverable                         |
| ------------------------ | ----------- | ----------------------------------- |
| Requirements approved    | 2025-03-20  | This PRD signed off                 |
| Design complete          | 2025-03-28  | UI mockups and interaction spec     |
| Implementation complete  | 2025-04-11  | Feature behind feature flag         |
| QA complete              | 2025-04-18  | All acceptance criteria verified    |
| Staged rollout (10%)     | 2025-04-21  | Monitor metrics for 3 days          |
| Full launch              | 2025-04-25  | Feature flag removed, 100% of users |

---

## 10. Open Questions

| Question                                                      | Owner   | Target Date |
| ------------------------------------------------------------- | ------- | ----------- |
| Should we support APO/FPO military addresses in Phase 1?      | Sam     | 2025-03-18  |
| What is the acceptable estimate accuracy tolerance (% vs actual)? | Jane | 2025-03-18  |
| Should the zip code input persist in local storage for returning anonymous users? | Alex | 2025-03-20 |
