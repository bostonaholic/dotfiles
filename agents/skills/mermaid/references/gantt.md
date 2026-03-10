# Gantt Charts

Gantt charts illustrate project schedules, showing tasks, durations, and dependencies.

## Basic Syntax

```mermaid
gantt
    title Project Schedule
    dateFormat YYYY-MM-DD
    section Planning
    Research           :a1, 2024-01-01, 30d
    Design             :a2, after a1, 20d
    section Development
    Implementation     :a3, after a2, 60d
    Testing            :a4, after a3, 30d
```

## Configuration

### Title

```mermaid
gantt
    title My Project Timeline
```

### Date Format

```mermaid
gantt
    dateFormat YYYY-MM-DD
```

Common formats:

- `YYYY-MM-DD` - 2024-01-15
- `DD-MM-YYYY` - 15-01-2024
- `YYYY-MM-DDTHH:mm` - 2024-01-15T09:30

### Axis Format

```mermaid
gantt
    axisFormat %Y-%m-%d
```

Format tokens:

- `%Y` - 4-digit year
- `%y` - 2-digit year
- `%m` - Month (01-12)
- `%d` - Day (01-31)
- `%H` - Hour (00-23)
- `%M` - Minute (00-59)
- `%S` - Second (00-59)
- `%b` - Abbreviated month
- `%B` - Full month name
- `%a` - Abbreviated weekday
- `%A` - Full weekday name
- `%W` - Week number

### Tick Interval

```mermaid
gantt
    tickInterval 1week
```

Options: `1day`, `1week`, `1month`

### Week Start

```mermaid
gantt
    weekday monday
```

Options: `sunday` (default), `monday`, `saturday`

### Excludes (Non-Working Days)

```mermaid
gantt
    excludes weekends
    excludes 2024-01-01, 2024-12-25
```

Options:

- `weekends` - Saturday and Sunday
- `saturday` or `sunday` - Specific day
- Specific dates in dateFormat

### Include Today Marker

```mermaid
gantt
    todayMarker stroke-width:5px,stroke:#0f0
```

Or disable:

```mermaid
gantt
    todayMarker off
```

## Sections

```mermaid
gantt
    section Phase 1
    Task 1.1 :a1, 2024-01-01, 10d
    Task 1.2 :a2, after a1, 10d
    section Phase 2
    Task 2.1 :b1, after a2, 15d
    Task 2.2 :b2, after b1, 15d
```

## Tasks

### Task Syntax

```text
TaskName :taskId, startDate, duration
TaskName :taskId, startDate, endDate
TaskName :taskId, after taskId, duration
```

### Task Status

```mermaid
gantt
    dateFormat YYYY-MM-DD
    section Status Examples
    Completed task    :done,    des1, 2024-01-01, 10d
    Active task       :active,  des2, 2024-01-11, 10d
    Future task       :         des3, 2024-01-21, 10d
    Critical task     :crit,    des4, 2024-02-01, 10d
    Critical done     :crit, done, des5, 2024-02-11, 5d
    Critical active   :crit, active, des6, 2024-02-16, 10d
```

Status keywords:

- `done` - Completed (grayed out)
- `active` - In progress (highlighted)
- `crit` - Critical path (red)

### Milestones

```mermaid
gantt
    dateFormat YYYY-MM-DD
    section Project
    Planning     :a1, 2024-01-01, 30d
    Milestone 1  :milestone, m1, after a1, 0d
    Development  :a2, after m1, 60d
    Milestone 2  :milestone, m2, after a2, 0d
```

### Duration Formats

```mermaid
gantt
    dateFormat YYYY-MM-DD
    section Durations
    Hours         :2024-01-01, 48h
    Days          :2024-01-03, 5d
    Weeks         :2024-01-08, 2w
    Until date    :2024-01-22, 2024-01-31
```

### Dependencies

```mermaid
gantt
    dateFormat YYYY-MM-DD
    section Dependencies
    Task A        :a, 2024-01-01, 10d
    Task B        :b, after a, 10d
    Task C        :c, after a, 15d
    Task D        :d, after b c, 10d
```

Use `after taskId` or `after taskId1 taskId2` for multiple dependencies.

## Complete Examples

### Software Development Project

```mermaid
gantt
    title Software Development Lifecycle
    dateFormat YYYY-MM-DD
    excludes weekends

    section Planning
    Requirements gathering :done, req, 2024-01-01, 2w
    Technical design       :done, des, after req, 2w
    Review & approval      :milestone, m1, after des, 0d

    section Development
    Backend development    :active, back, after m1, 6w
    Frontend development   :active, front, after m1, 6w
    Integration            :int, after back front, 2w

    section Testing
    Unit testing           :test1, after back, 2w
    Integration testing    :crit, test2, after int, 2w
    UAT                    :uat, after test2, 1w
    Release                :milestone, crit, rel, after uat, 0d
```

### Marketing Campaign

```mermaid
gantt
    title Q1 Marketing Campaign
    dateFormat YYYY-MM-DD
    axisFormat %b %d

    section Research
    Market analysis    :done, r1, 2024-01-01, 14d
    Competitor review  :done, r2, 2024-01-08, 10d
    Audience research  :done, r3, after r1, 7d

    section Creative
    Concept development :active, c1, after r3, 14d
    Design work         :c2, after c1, 21d
    Copy writing        :c3, after c1, 14d
    Review cycles       :c4, after c2 c3, 7d

    section Launch
    Asset preparation  :l1, after c4, 7d
    Soft launch        :milestone, l2, after l1, 0d
    Full campaign      :crit, l3, after l2, 30d
    Analysis           :l4, after l3, 14d
```

### Sprint Planning

```mermaid
gantt
    title Sprint 23 - User Authentication
    dateFormat YYYY-MM-DD
    excludes weekends
    todayMarker stroke-width:3px,stroke:#00f

    section Stories
    US-101 Login page    :crit, done, us101, 2024-03-01, 2d
    US-102 OAuth setup   :crit, active, us102, after us101, 3d
    US-103 Password reset :us103, after us102, 2d
    US-104 2FA           :us104, after us103, 3d

    section Bugs
    BUG-201 Session fix  :done, bug201, 2024-03-01, 1d
    BUG-202 Token expiry :bug202, after bug201, 1d

    section Technical Debt
    TD-301 Refactor auth :td301, after us104, 2d
```

### Event Planning

```mermaid
gantt
    title Annual Conference 2024
    dateFormat YYYY-MM-DD

    section Venue
    Venue research      :done, v1, 2024-01-15, 30d
    Contract negotiation :done, v2, after v1, 14d
    Deposit payment     :milestone, v3, after v2, 0d

    section Speakers
    Speaker outreach    :active, s1, 2024-02-01, 60d
    Confirm speakers    :s2, after s1, 30d
    Schedule finalization :s3, after s2, 14d

    section Marketing
    Save the date       :m1, 2024-03-01, 7d
    Early bird registration :m2, after m1, 45d
    Full marketing push :m3, after m2, 60d

    section Logistics
    Catering setup      :l1, after v3, 30d
    AV requirements     :l2, after s3, 21d
    Volunteer coordination :l3, 2024-06-01, 30d

    section Event
    Conference Day 1    :milestone, crit, e1, 2024-07-15, 0d
    Conference Day 2    :milestone, crit, e2, 2024-07-16, 0d
```

## Styling

### Theme Configuration

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {
    'primaryColor': '#ff6b6b',
    'primaryTextColor': '#fff',
    'primaryBorderColor': '#ff5252',
    'sectionBkgColor': '#ffeaa7',
    'taskBkgColor': '#74b9ff',
    'taskTextLightColor': '#fff'
}}}%%
gantt
    title Styled Gantt
    section Section
    Task 1 :a1, 2024-01-01, 30d
    Task 2 :a2, after a1, 20d
```

## Best Practices

1. Use meaningful task IDs for dependencies
2. Group related tasks into sections
3. Mark completed tasks as `done`
4. Highlight critical path with `crit`
5. Use milestones for key dates
6. Exclude weekends for realistic schedules
7. Keep task names concise
8. Use consistent date format
9. Add a clear title

## Common Issues

### Tasks Not Showing

Ensure dateFormat matches your dates:

```mermaid
gantt
    dateFormat YYYY-MM-DD
    Task 1 :2024-01-01, 10d   %% Correct
    Task 2 :01-01-2024, 10d   %% Wrong format
```

### Dependencies Not Working

Use `after` keyword correctly:

```mermaid
gantt
    Task A :a, 2024-01-01, 10d
    Task B :b, after a, 10d      %% Correct
    Task C :c, a, 10d            %% Wrong - missing 'after'
```
