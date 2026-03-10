# Sequence Diagrams

Sequence diagrams show interactions between participants over time.

## Basic Syntax

```mermaid
sequenceDiagram
    participant A as Alice
    participant B as Bob
    A->>B: Hello Bob!
    B-->>A: Hi Alice!
```

## Participants

### Declaration

```mermaid
sequenceDiagram
    participant A as Alice
    actor U as User
    participant S as Server
    participant D as Database
```

### Participant Types

- `participant` - Box shape (default)
- `actor` - Person/stick figure shape

### Auto-numbering

```mermaid
sequenceDiagram
    autonumber
    Alice->>Bob: First message
    Bob->>Alice: Second message
    Alice->>Bob: Third message
```

## Message Types

```mermaid
sequenceDiagram
    A->B: Solid line without arrow
    A-->B: Dotted line without arrow
    A->>B: Solid line with arrow
    A-->>B: Dotted line with arrow
    A-xB: Solid line with cross
    A--xB: Dotted line with cross
    A-)B: Solid line with open arrow (async)
    A--)B: Dotted line with open arrow (async)
```

### Bidirectional Messages

```mermaid
sequenceDiagram
    A<<->>B: Bidirectional solid
    A<<-->>B: Bidirectional dotted
```

## Activations

```mermaid
sequenceDiagram
    Alice->>+Bob: Request
    Bob-->>-Alice: Response
```

Or explicit:

```mermaid
sequenceDiagram
    Alice->>Bob: Request
    activate Bob
    Bob-->>Alice: Response
    deactivate Bob
```

### Nested Activations

```mermaid
sequenceDiagram
    Alice->>+Bob: Request
    Bob->>+Charlie: Forward
    Charlie-->>-Bob: Reply
    Bob-->>-Alice: Response
```

## Notes

```mermaid
sequenceDiagram
    participant A as Alice
    participant B as Bob
    Note right of A: Note to the right
    Note left of B: Note to the left
    Note over A: Note over A
    Note over A,B: Note spanning both
```

## Loops

```mermaid
sequenceDiagram
    Alice->>Bob: Request
    loop Every minute
        Bob->>Alice: Heartbeat
    end
```

## Alternatives (Alt/Else)

```mermaid
sequenceDiagram
    Alice->>Bob: Request
    alt is valid
        Bob->>Alice: Success
    else is invalid
        Bob->>Alice: Error
    end
```

### Optional (Opt)

```mermaid
sequenceDiagram
    Alice->>Bob: Request
    opt Extra logging
        Bob->>Logger: Log event
    end
    Bob->>Alice: Response
```

## Parallel (Par)

```mermaid
sequenceDiagram
    par Alice to Bob
        Alice->>Bob: Message 1
    and Alice to Charlie
        Alice->>Charlie: Message 2
    end
```

## Critical Region

```mermaid
sequenceDiagram
    critical Establish connection
        Service->>DB: Connect
    option Network failure
        Service->>Logger: Log error
    option Timeout
        Service->>Logger: Log timeout
    end
```

## Break

```mermaid
sequenceDiagram
    Consumer->>API: Request
    API->>API: Validate
    break when validation fails
        API->>Consumer: Error response
    end
    API->>Database: Query
```

## Grouping with Rect

```mermaid
sequenceDiagram
    rect rgb(200, 220, 240)
        Alice->>Bob: Request
        Bob->>Alice: Response
    end
```

## Links

```mermaid
sequenceDiagram
    participant A as Alice
    link A: Dashboard @ https://dashboard.example.com
    link A: Wiki @ https://wiki.example.com
```

## Comments

```mermaid
sequenceDiagram
    %% This is a comment
    Alice->>Bob: Hello
```

## Styling

### Actor Styles

```mermaid
%%{init: {
  'theme': 'base',
  'themeVariables': {
    'actorBkg': '#ff0000',
    'actorBorder': '#000000',
    'actorTextColor': '#ffffff'
  }
}}%%
sequenceDiagram
    Alice->>Bob: Hello
```

### Custom Styling with CSS Classes

```mermaid
sequenceDiagram
    participant A as Alice
    participant B as Bob
    A->>B: Message
```

## Best Practices

1. List participants explicitly for control over order
2. Use meaningful participant aliases
3. Group related messages with rect backgrounds
4. Use activation bars to show processing time
5. Add notes to explain complex logic
6. Use autonumber for reference in documentation
7. Keep diagrams focused - split complex flows into multiple diagrams

## Common Patterns

### Request-Response

```mermaid
sequenceDiagram
    Client->>+Server: HTTP Request
    Server->>+Database: Query
    Database-->>-Server: Results
    Server-->>-Client: HTTP Response
```

### Authentication Flow

```mermaid
sequenceDiagram
    autonumber
    User->>+App: Login request
    App->>+AuthService: Validate credentials
    AuthService->>+Database: Check user
    Database-->>-AuthService: User data
    AuthService-->>-App: Token
    App-->>-User: Success + Token
```

### Error Handling

```mermaid
sequenceDiagram
    Client->>+Server: Request
    alt Success
        Server-->>Client: 200 OK
    else Validation Error
        Server-->>Client: 400 Bad Request
    else Server Error
        Server-->>Client: 500 Error
    end
    deactivate Server
```
