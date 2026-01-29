# Flowcharts

Flowcharts are composed of nodes (geometric shapes) and edges (arrows or lines).

## Basic Syntax

```mermaid
flowchart TD
    A[Start] --> B{Decision}
    B -->|Yes| C[Action 1]
    B -->|No| D[Action 2]
    C --> E[End]
    D --> E
```

## Graph Direction

- `TB` or `TD` - Top to bottom (default)
- `BT` - Bottom to top
- `LR` - Left to right
- `RL` - Right to left

```mermaid
flowchart LR
    A --> B --> C
```

## Node Shapes

```mermaid
flowchart TD
    A[Rectangle]
    B(Rounded rectangle)
    C([Stadium/pill])
    D[[Subroutine]]
    E[(Database/cylinder)]
    F((Circle))
    G>Asymmetric/flag]
    H{Diamond/rhombus}
    I{{Hexagon}}
    J[/Parallelogram/]
    K[\Parallelogram alt\]
    L[/Trapezoid\]
    M[\Trapezoid alt/]
    N(((Double circle)))
```

## Links/Edges

### Arrow Types

```mermaid
flowchart LR
    A --> B           %% Arrow
    C --- D           %% Open link (no arrow)
    E -.- F           %% Dotted link
    G -.-> H          %% Dotted arrow
    I ==> J           %% Thick arrow
    K ~~~ L           %% Invisible link
    M <--> N          %% Multi-directional
    O o--o P          %% Circle endpoints
    Q x--x R          %% Cross endpoints
```

### Link Text

```mermaid
flowchart LR
    A -->|text| B
    C -- text --> D
    E -.->|dotted text| F
    G ==>|thick text| H
```

### Link Length

Add extra dashes/dots to make links longer:

```mermaid
flowchart TD
    A ---> B          %% Longer
    C ----> D         %% Even longer
    E -.....-> F      %% Long dotted
```

## Subgraphs

```mermaid
flowchart TB
    subgraph one [Title One]
        A1 --> A2
    end
    subgraph two [Title Two]
        B1 --> B2
    end
    subgraph three [Title Three]
        C1 --> C2
    end
    one --> two
    three --> two
    two --> C2
```

### Subgraph Direction

```mermaid
flowchart LR
    subgraph TOP
        direction TB
        A --> B
    end
    subgraph BOTTOM
        direction LR
        C --> D
    end
    TOP --> BOTTOM
```

## Special Characters

Use quotes for special characters in node text:

```mermaid
flowchart LR
    A["Text with (parentheses)"]
    B["Text with 'quotes'"]
    C["Text with #quot;double#quot;"]
```

### Entity Codes

- `#quot;` - Double quote
- `#39;` - Single quote
- `#lt;` - Less than
- `#gt;` - Greater than
- `#amp;` - Ampersand

## Comments

```mermaid
flowchart LR
    %% This is a comment
    A --> B
```

## Styling

### Inline Styling

```mermaid
flowchart LR
    A:::someclass --> B
    classDef someclass fill:#f9f,stroke:#333,stroke-width:2px
```

### Style Definitions

```mermaid
flowchart LR
    A --> B --> C

    classDef default fill:#fff,stroke:#333
    classDef highlight fill:#ff0,stroke:#f00,stroke-width:4px
    classDef special color:#fff,fill:#333

    class A highlight
    class B,C special
```

### Link Styling

```mermaid
flowchart LR
    A --> B --> C
    linkStyle 0 stroke:#ff0,stroke-width:4px
    linkStyle 1 stroke:#0ff,stroke-width:2px,stroke-dasharray:5 5
```

## Click Events

```mermaid
flowchart LR
    A --> B
    click A "https://example.com" "Tooltip text"
    click B callback "Tooltip for B"
    click A call callback() "Call function"
```

## Multiple Nodes Declaration

```mermaid
flowchart LR
    A & B --> C & D
```

Equivalent to:

```mermaid
flowchart LR
    A --> C
    A --> D
    B --> C
    B --> D
```

## Icon Support

```mermaid
flowchart TD
    A@{ icon: "fa:home", form: "square", label: "Home", pos: "t", h: 60 }
    B@{ icon: "fa:user" }
    A --> B
```

Icon options:

- `icon` - FontAwesome icon (fa:iconname)
- `form` - Shape: square, circle, rounded
- `label` - Text label
- `pos` - Label position: t, b, l, r
- `h` - Height in pixels

## Best Practices

1. Use meaningful node IDs (e.g., `start`, `validateInput` instead of `A`, `B`)
2. Keep flowcharts readable - split complex diagrams into subgraphs
3. Use consistent direction within subgraphs
4. Add labels to edges when the relationship isn't obvious
5. Use appropriate node shapes (diamonds for decisions, cylinders for databases)
