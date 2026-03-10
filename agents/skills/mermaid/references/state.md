# State Diagrams

State diagrams describe system behavior by showing states and transitions.

## Basic Syntax

```mermaid
stateDiagram-v2
    [*] --> Still
    Still --> Moving
    Moving --> Still
    Moving --> Crash
    Crash --> [*]
```

## States

### Simple States

```mermaid
stateDiagram-v2
    state1
    state2 : This is state 2
    state3 : State with
    note right of state3 : Multi-line description
```

### Start and End States

```mermaid
stateDiagram-v2
    [*] --> Active
    Active --> [*]
```

## Transitions

### Basic Transitions

```mermaid
stateDiagram-v2
    Idle --> Processing
    Processing --> Complete
```

### Labeled Transitions

```mermaid
stateDiagram-v2
    Idle --> Processing : start
    Processing --> Complete : finish
    Processing --> Error : fail
```

## Composite States

```mermaid
stateDiagram-v2
    [*] --> First

    state First {
        [*] --> A
        A --> B
        B --> [*]
    }

    First --> Second

    state Second {
        [*] --> C
        C --> D
        D --> [*]
    }

    Second --> [*]
```

### Nested Composite States

```mermaid
stateDiagram-v2
    [*] --> Outer

    state Outer {
        [*] --> Inner1

        state Inner1 {
            [*] --> Deep
            Deep --> [*]
        }

        Inner1 --> Inner2

        state Inner2 {
            [*] --> Deep2
            Deep2 --> [*]
        }
    }
```

## Choice (Branching)

```mermaid
stateDiagram-v2
    state if_state <<choice>>
    [*] --> Validate
    Validate --> if_state
    if_state --> Valid : valid
    if_state --> Invalid : invalid
    Valid --> [*]
    Invalid --> [*]
```

## Forks and Joins

```mermaid
stateDiagram-v2
    state fork_state <<fork>>
    state join_state <<join>>

    [*] --> fork_state
    fork_state --> State1
    fork_state --> State2

    State1 --> join_state
    State2 --> join_state

    join_state --> [*]
```

## Notes

```mermaid
stateDiagram-v2
    State1 : The first state
    State1 --> State2
    note right of State1 : Important note
    note left of State2 : Another note
```

## Concurrency

```mermaid
stateDiagram-v2
    [*] --> Active

    state Active {
        [*] --> Process1
        --
        [*] --> Process2
    }

    Active --> [*]
```

The `--` separator creates parallel regions.

## Direction

```mermaid
stateDiagram-v2
    direction LR
    [*] --> A
    A --> B
    B --> [*]
```

Options: `TB` (default), `BT`, `LR`, `RL`

## Styling

### Class Definitions

```mermaid
stateDiagram-v2
    classDef badState fill:#f00,color:white
    classDef goodState fill:#0f0

    [*] --> Processing
    Processing --> Success
    Processing --> Failure

    class Success goodState
    class Failure badState
```

### Inline Styling

```mermaid
stateDiagram-v2
    [*] --> Active
    Active --> Done
    Done --> [*]

    style Active fill:#f9f,stroke:#333
```

## Complete Examples

### Order Processing

```mermaid
stateDiagram-v2
    [*] --> Pending

    Pending --> Processing : payment received
    Processing --> Shipped : items packed
    Shipped --> Delivered : delivered
    Delivered --> [*]

    Processing --> Cancelled : cancel request
    Pending --> Cancelled : cancel request
    Cancelled --> [*]

    state Processing {
        [*] --> Picking
        Picking --> Packing
        Packing --> [*]
    }
```

### Traffic Light

```mermaid
stateDiagram-v2
    direction LR
    [*] --> Red
    Red --> Green : timer
    Green --> Yellow : timer
    Yellow --> Red : timer
```

### User Authentication

```mermaid
stateDiagram-v2
    [*] --> LoggedOut

    LoggedOut --> Authenticating : login attempt

    state Authenticating {
        [*] --> ValidatingCredentials
        ValidatingCredentials --> CheckingMFA : credentials valid
        ValidatingCredentials --> Failed : credentials invalid
        CheckingMFA --> Success : MFA valid
        CheckingMFA --> Failed : MFA invalid
    }

    Authenticating --> LoggedIn : Success
    Authenticating --> LoggedOut : Failed

    LoggedIn --> LoggedOut : logout
    LoggedIn --> SessionExpired : timeout
    SessionExpired --> LoggedOut : acknowledge
```

### Document Workflow

```mermaid
stateDiagram-v2
    [*] --> Draft

    Draft --> InReview : submit
    InReview --> Draft : request changes
    InReview --> Approved : approve

    state if_priority <<choice>>
    Approved --> if_priority
    if_priority --> FastTrack : high priority
    if_priority --> Standard : normal priority

    FastTrack --> Published
    Standard --> Scheduled
    Scheduled --> Published : publish date reached

    Published --> Archived : archive
    Published --> Draft : revise
    Archived --> [*]
```

## Best Practices

1. Always include start `[*]` and end `[*]` states where appropriate
2. Use descriptive state names
3. Label transitions with trigger events
4. Use composite states to group related states
5. Use choice nodes for conditional branching
6. Add notes to explain complex states
7. Keep diagrams focused on one aspect of the system

## v1 vs v2 Syntax

Use `stateDiagram-v2` for:

- Better rendering
- Direction support
- Fork/join states
- Choice states
- Concurrent regions
- Better styling support

The original `stateDiagram` is deprecated.
