# Block Diagrams

Block diagrams provide precise control over layout and positioning,
unlike flowcharts which use automatic layout.

## Basic Syntax

```mermaid
block-beta
    columns 3
    a["Block A"] b["Block B"] c["Block C"]
    d["Block D"]:2 e["Block E"]
```

## Columns

Define the number of columns for the layout:

```mermaid
block-beta
    columns 4
    a b c d
    e f g h
```

Blocks fill left-to-right, wrapping to next row.

## Block Definitions

### Simple Blocks

```mermaid
block-beta
    columns 2
    a b
    c d
```

### Blocks with Labels

```mermaid
block-beta
    columns 2
    a["First Block"]
    b["Second Block"]
```

### Block Spanning

Span multiple columns with `:n`:

```mermaid
block-beta
    columns 3
    header["Header"]:3
    left["Left"] middle["Middle"] right["Right"]
    footer["Footer"]:3
```

## Block Shapes

```mermaid
block-beta
    columns 4
    rect["Rectangle"]
    rounded("Rounded")
    stadium(["Stadium"])
    subroutine[["Subroutine"]]
    cylinder[("Cylinder")]
    circle(("Circle"))
    rhombus{"Rhombus"}
    hexagon{{"Hexagon"}}
```

### All Shape Syntax

- `["text"]` - Rectangle (default)
- `("text")` - Rounded rectangle
- `(["text"])` - Stadium/pill shape
- `[["text"]]` - Subroutine
- `[("text")]` - Cylinder/database
- `(("text"))` - Circle
- `{"text"}` - Rhombus/diamond
- `{{"text"}}` - Hexagon
- `[/"text"/]` - Parallelogram
- `[\"text"\]` - Parallelogram (alt)
- `[/"text"\]` - Trapezoid
- `[\"text"/]` - Trapezoid (alt)
- `))text((` - Cloud
- `)text(` - Bang

## Space Blocks

Create empty space in the layout:

```mermaid
block-beta
    columns 3
    a space b
    space:2 c
```

### Multiple Spaces

```mermaid
block-beta
    columns 4
    a space:2 b
    c d space e
```

## Composite Blocks

Nest blocks within blocks:

```mermaid
block-beta
    columns 3

    block:group1:2
        columns 2
        a["A"] b["B"]
        c["C"] d["D"]
    end
    e["E"]

    f["F"]:3
```

### Deep Nesting

```mermaid
block-beta
    columns 2

    block:outer:2
        columns 2
        block:inner1
            a["A"]
            b["B"]
        end
        block:inner2
            c["C"]
            d["D"]
        end
    end
```

## Connections

### Basic Arrows

```mermaid
block-beta
    columns 3
    a["A"] --> b["B"] --> c["C"]
```

### Connection Types

```mermaid
block-beta
    columns 2
    a["A"] --> b["B"]
    c["C"] --- d["D"]
    e["E"] -.-> f["F"]
    g["G"] ==> h["H"]
```

### Labels on Connections

```mermaid
block-beta
    columns 2
    a["Start"] -- "process" --> b["End"]
```

## Complete Examples

### System Architecture

```mermaid
block-beta
    columns 3

    block:client:3
        columns 3
        web["Web App"] mobile["Mobile App"] desktop["Desktop"]
    end

    space:3

    block:api:3
        columns 1
        gateway["API Gateway"]:3
    end

    space:3

    block:services:3
        columns 3
        auth["Auth Service"]
        users["User Service"]
        orders["Order Service"]
    end

    space:3

    block:data:3
        columns 3
        cache[("Redis")]
        db[("PostgreSQL")]
        search[("Elasticsearch")]
    end

    web --> gateway
    mobile --> gateway
    desktop --> gateway
    gateway --> auth
    gateway --> users
    gateway --> orders
    auth --> cache
    users --> db
    orders --> db
    orders --> search
```

### Dashboard Layout

```mermaid
block-beta
    columns 4

    header["Dashboard Header"]:4

    nav["Navigation"]:1
    block:main:3
        columns 3
        card1["Metric 1"]
        card2["Metric 2"]
        card3["Metric 3"]
        chart["Chart View"]:2
        table["Data Table"]
    end

    footer["Footer"]:4
```

### Network Topology

```mermaid
block-beta
    columns 5

    space:2 internet(("Internet")) space:2

    space:5

    space:2 firewall{{"Firewall"}} space:2

    space:5

    space:2 router["Router"] space:2

    space:5

    switch1["Switch 1"] space switch2["Switch 2"] space switch3["Switch 3"]

    space:5

    server1[("Server 1")] server2[("Server 2")]
    space server3[("Server 3")] server4[("Server 4")]

    internet --> firewall
    firewall --> router
    router --> switch1
    router --> switch2
    router --> switch3
    switch1 --> server1
    switch1 --> server2
    switch3 --> server3
    switch3 --> server4
```

### Org Chart

```mermaid
block-beta
    columns 5

    space:2 ceo["CEO"]:1 space:2

    space:5

    space cto["CTO"] space cfo["CFO"] space

    space:5

    eng["Engineering"] product["Product"] space finance["Finance"] ops["Operations"]

    ceo --> cto
    ceo --> cfo
    cto --> eng
    cto --> product
    cfo --> finance
    cfo --> ops
```

### Process Flow

```mermaid
block-beta
    columns 4

    start(["Start"]) --> input["Input Data"]
    input --> validate{"Valid?"}
    validate -- "Yes" --> process["Process"]
    validate -- "No" --> error["Show Error"]
    error --> input
    process --> output["Output Results"]
    output --> finish(["End"])
```

## Styling

### Class-Based Styling

```mermaid
block-beta
    columns 2
    a["Success"]:::success
    b["Warning"]:::warning
    c["Error"]:::error
    d["Info"]:::info

    classDef success fill:#d4edda,stroke:#28a745
    classDef warning fill:#fff3cd,stroke:#ffc107
    classDef error fill:#f8d7da,stroke:#dc3545
    classDef info fill:#d1ecf1,stroke:#17a2b8
```

### Inline Styling

```mermaid
block-beta
    columns 2
    a["Block A"]
    b["Block B"]

    style a fill:#ff6b6b,stroke:#333
    style b fill:#4ecdc4,stroke:#333
```

## Best Practices

1. Plan your column count based on layout needs
2. Use spanning for headers and footers
3. Use space blocks for alignment
4. Group related elements in composite blocks
5. Keep nesting to 2-3 levels maximum
6. Use consistent shapes for similar elements
7. Add labels to connections when needed
8. Style blocks to indicate status or type

## Comparison: Block vs Flowchart

| Feature | Block Diagram | Flowchart |
| --- | --- | --- |
| Layout | Manual (columns) | Automatic |
| Positioning | Precise control | Algorithm-driven |
| Complex layouts | Better | Limited |
| Quick diagrams | More verbose | Simpler |
| Responsiveness | Fixed | Adapts |

## When to Use Block Diagrams

Good for:

- Dashboard/UI mockups
- Fixed-layout documentation
- Org charts with specific positioning
- System architecture with precise layout
- Grid-based visualizations

Avoid when:

- Simple flowcharts suffice
- Layout flexibility is needed
- Automatic arrangement is preferred
