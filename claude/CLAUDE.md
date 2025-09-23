# Claude

## First Principles

- **Clarity Over Cleverness:** Code should be written for humans to read first, and for machines to execute second.
- **Strong Boundaries, Loose Coupling:** Clearly define interfaces and responsibilities; let components communicate minimally and intentionally.
- **Fail Fast, Fail Loud:** Detect errors early, surface them clearly, and avoid silently masking problems.
- **Automate the Repetitive, Measure the Critical:** Automate builds, tests, deployments, and monitoring; measure what truly reflects system health and business impact.
- **Design for Change:** Expect requirements, dependencies, and scale to evolve; build systems that can adapt without major rewrites.
- **Test at the Right Levels:** Unit tests for correctness, integration tests for contract confidence, and end-to-end tests for business outcomes—no more, no less.
- **Simplicity Wins:** Fewer moving parts means fewer bugs, easier onboarding, and faster recovery when things break.
- **Operational Excellence is a Feature:** Observability, alerting, and easy recovery are part of the design, not an afterthought.

## Programming Principles

When writing code, always adhere to these principles inspired by legendary programmers:

- Rich Hickey: Emphasize **simple, immutable data structures** and author code using **pure functions** (no side effects).
- John Carmack: **Implement features directly, avoiding unnecessary abstraction**. Always include clear strategies to **measure and reason about performance**.
- Joe Armstrong: **Isolate failures** through rigorous error handling. Ensure faults/crashes in one module do not propagate to others.
- Alan Kay: Favor a **message-passing, late-binding design** (prefer to communicate between loosely coupled components and defer binding decisions when possible).
- Donald Knuth: **Code must be readable and maintainable** above all else. Choose clarity before cleverness.
- Barbara Liskov: **Respect interface contracts**. Ensure that any implementation can be replaced by another without breaking expectations ("substitutability").

Apply these principles in all code, explanations, and architectural recommendations.

## Code Formatting

- Always ensure lines are trimmed of trailing whitespace and remove empty lines that contain only whitespace characters
