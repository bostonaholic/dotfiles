# Kanban Boards

Kanban diagrams visualize workflow with columns and task cards.

## Basic Syntax

```mermaid
kanban
    Todo
        task1[Design mockups]
        task2[Write specs]
    In Progress
        task3[Implement feature]
    Done
        task4[Code review]
        task5[Testing]
```

## Columns

Define columns with their title:

```mermaid
kanban
    Backlog
    Todo
    In Progress
    Review
    Done
```

### Column with ID and Title

```mermaid
kanban
    backlog[Backlog]
    todo[To Do]
    progress[In Progress]
    review[In Review]
    done[Done]
```

## Tasks

Tasks are indented under columns:

```mermaid
kanban
    Todo
        id1[Task description]
        id2[Another task]
```

### Task Syntax

```text
taskId[Task Description]
```

- **taskId** - Unique identifier for the task
- **Task Description** - Display text in brackets

## Task Metadata

Add metadata using `@{ }` syntax:

```mermaid
kanban
    Todo
        task1[Fix login bug]@{ assigned: Alice, priority: High }
        task2[Update docs]@{ assigned: Bob, ticket: DOC-123 }
    In Progress
        task3[New feature]@{ assigned: Carol, priority: Medium }
```

### Supported Metadata Keys

- `assigned` - Task owner/assignee
- `ticket` - Issue/ticket reference number
- `priority` - Task priority level

### Priority Values

- `Very High` - Critical priority
- `High` - High priority
- `Low` - Low priority
- `Very Low` - Minimal priority

## Configuration

### Ticket URL Base

Link tickets to external systems:

```yaml
---
config:
  kanban:
    ticketBaseUrl: 'https://jira.example.com/browse/#TICKET#'
---
```

The `#TICKET#` placeholder is replaced with the ticket value.

### Full Configuration Example

```mermaid
---
config:
  kanban:
    ticketBaseUrl: 'https://github.com/org/repo/issues/#TICKET#'
---
kanban
    Backlog
        feat1[Add dark mode]@{ ticket: 42, priority: High }
        feat2[Improve search]@{ ticket: 43 }
    In Progress
        feat3[User auth]@{ ticket: 38, assigned: Alice }
    Done
        feat4[Bug fix]@{ ticket: 35, assigned: Bob }
```

## Complete Examples

### Sprint Board

```mermaid
kanban
    Backlog
        us1[US-101: User registration]@{ priority: High }
        us2[US-102: Password reset]@{ priority: Medium }
        us3[US-103: Email verification]
    Sprint Backlog
        us4[US-104: Login page]@{ assigned: Alice }
        us5[US-105: OAuth integration]@{ assigned: Bob }
    In Development
        us6[US-106: Session management]@{ assigned: Carol, priority: High }
    Code Review
        us7[US-107: Logout functionality]@{ assigned: Dave }
    Testing
        us8[US-108: Remember me]@{ assigned: Eve }
    Done
        us9[US-109: Security headers]
```

### Bug Tracking

```mermaid
---
config:
  kanban:
    ticketBaseUrl: 'https://bugs.example.com/#TICKET#'
---
kanban
    New
        bug1[Login fails on Safari]@{ ticket: BUG-201, priority: Very High }
        bug2[Broken image on homepage]@{ ticket: BUG-202 }
    Triaged
        bug3[Slow query on dashboard]@{ ticket: BUG-198, priority: High }
    Investigating
        bug4[Memory leak in worker]@{ ticket: BUG-195, assigned: Alice }
    In Progress
        bug5[Fix timezone handling]@{ ticket: BUG-190, assigned: Bob }
    Verification
        bug6[Incorrect calculations]@{ ticket: BUG-185, assigned: Carol }
    Closed
        bug7[Typo in error message]@{ ticket: BUG-180 }
```

### Personal Task Board

```mermaid
kanban
    Ideas
        idea1[Learn Rust]
        idea2[Build portfolio site]
        idea3[Write blog post]
    This Week
        week1[Finish course module]@{ priority: High }
        week2[Review PRs]
    Today
        today1[Team standup]@{ priority: High }
        today2[Code review for feature X]
        today3[Update documentation]
    Blocked
        blocked1[Waiting for API access]
    Done
        done1[Setup dev environment]
        done2[Initial project scaffolding]
```

### Feature Development

```mermaid
kanban
    Discovery
        f1[User research]@{ assigned: UX Team }
        f2[Competitive analysis]
    Design
        f3[Wireframes]@{ assigned: Alice, priority: High }
        f4[Visual design]@{ assigned: Bob }
    Development
        f5[Backend API]@{ assigned: Carol }
        f6[Frontend implementation]@{ assigned: Dave }
    QA
        f7[Functional testing]@{ assigned: QA Team }
    Staging
        f8[Integration testing]
    Production
        f9[Monitoring]
```

### Content Pipeline

```mermaid
kanban
    Ideas
        c1[Tutorial series]
        c2[Case study]
    Research
        c3[Interview experts]@{ assigned: Writer1 }
    Writing
        c4[Draft blog post]@{ assigned: Writer2, priority: High }
    Editing
        c5[Review article]@{ assigned: Editor }
    Design
        c6[Create graphics]@{ assigned: Designer }
    Scheduled
        c7[Social media posts]
    Published
        c8[Product announcement]
        c9[Monthly newsletter]
```

## Best Practices

1. Use clear, descriptive task names
2. Limit WIP (Work In Progress) in middle columns
3. Keep columns consistent across the team
4. Use metadata for filtering and searching
5. Link tickets to your issue tracker
6. Assign owners to active tasks
7. Use priority for critical items
8. Keep Done column for visibility (archive periodically)

## Limitations

- No drag-and-drop interactivity
- No swimlanes
- No WIP limits enforcement
- Limited styling options
- No custom fields beyond built-in metadata
- Static representation only

## When to Use Kanban Diagrams

Good for:

- Sprint/project status visualization
- Task tracking documentation
- Team workflow overview
- Status reports
- Process documentation

Avoid when:

- Need interactive board (use Trello, Jira)
- Complex workflows with automation
- Real-time collaboration required
- Detailed time tracking needed
