# Styling and Configuration

Comprehensive guide to styling and configuring Mermaid diagrams.

## Configuration Methods

### 1. Init Directive

Inline configuration at the start of a diagram:

```mermaid
%%{init: {'theme': 'forest'}}%%
flowchart LR
    A --> B
```

### 2. Frontmatter (YAML)

YAML block at the start:

```mermaid
---
config:
  theme: forest
  flowchart:
    curve: basis
---
flowchart LR
    A --> B
```

### 3. JavaScript Configuration

For programmatic use:

```javascript
mermaid.initialize({
  theme: 'dark',
  flowchart: {
    curve: 'basis'
  }
});
```

## Themes

### Built-in Themes

```mermaid
%%{init: {'theme': 'default'}}%%
```

Available themes:

- `default` - Standard theme
- `dark` - Dark mode
- `forest` - Green tones
- `neutral` - Grayscale
- `base` - Minimal, for customization

### Theme Variables

Customize with `themeVariables`:

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {
    'primaryColor': '#ff6b6b',
    'primaryTextColor': '#fff',
    'primaryBorderColor': '#ff5252',
    'lineColor': '#333',
    'secondaryColor': '#4ecdc4',
    'tertiaryColor': '#f9f9f9'
}}}%%
flowchart LR
    A[Primary] --> B[Secondary]
    B --> C[Tertiary]
```

### Common Theme Variables

| Variable | Description |
| --- | --- |
| `primaryColor` | Main node color |
| `primaryTextColor` | Text on primary |
| `primaryBorderColor` | Primary borders |
| `secondaryColor` | Secondary elements |
| `tertiaryColor` | Tertiary elements |
| `lineColor` | Connection lines |
| `textColor` | General text |
| `mainBkg` | Background color |
| `nodeBorder` | Node borders |
| `clusterBkg` | Subgraph background |
| `clusterBorder` | Subgraph borders |
| `titleColor` | Title text |
| `edgeLabelBackground` | Edge label background |

## Flowchart-Specific Styling

### Node Classes

```mermaid
flowchart LR
    A:::highlight --> B:::success --> C:::error

    classDef highlight fill:#ff0,stroke:#333,stroke-width:4px
    classDef success fill:#0f0,stroke:#0a0
    classDef error fill:#f00,stroke:#a00,color:#fff
```

### Default Class

```mermaid
flowchart LR
    A --> B --> C

    classDef default fill:#fff,stroke:#333,stroke-width:2px
```

### Apply Classes

```mermaid
flowchart LR
    A --> B --> C

    class A,C highlighted
    classDef highlighted fill:#ff0
```

### Link Styling

```mermaid
flowchart LR
    A --> B --> C --> D

    linkStyle 0 stroke:#ff0,stroke-width:4px
    linkStyle 1 stroke:#0ff,stroke-width:2px
    linkStyle 2 stroke:#f0f,stroke-width:2px,stroke-dasharray: 5 5
```

### Link Style Properties

- `stroke` - Line color
- `stroke-width` - Line thickness
- `stroke-dasharray` - Dash pattern (e.g., `5 5`)
- `fill` - Fill color (for arrow heads)

### Subgraph Styling

```mermaid
flowchart TB
    subgraph sg1 [Subgraph 1]
        A --> B
    end
    subgraph sg2 [Subgraph 2]
        C --> D
    end

    style sg1 fill:#f9f,stroke:#333,stroke-width:2px
    style sg2 fill:#bbf,stroke:#333,stroke-width:2px
```

## Sequence Diagram Styling

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {
    'actorBkg': '#326ce5',
    'actorBorder': '#1a3d7c',
    'actorTextColor': '#fff',
    'actorLineColor': '#333',
    'signalColor': '#333',
    'signalTextColor': '#333',
    'labelBoxBkgColor': '#f9f9f9',
    'labelBoxBorderColor': '#333',
    'labelTextColor': '#333',
    'loopTextColor': '#333',
    'noteBkgColor': '#fff5ad',
    'noteBorderColor': '#aaaa33',
    'noteTextColor': '#333',
    'activationBkgColor': '#f4f4f4',
    'activationBorderColor': '#666',
    'sequenceNumberColor': '#fff'
}}}%%
sequenceDiagram
    Alice->>Bob: Hello
    Bob-->>Alice: Hi
```

## Class Diagram Styling

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {
    'classText': '#333'
}}}%%
classDiagram
    class Animal {
        +name: string
        +age: int
    }

    style Animal fill:#f9f,stroke:#333
```

## State Diagram Styling

```mermaid
stateDiagram-v2
    [*] --> Active
    Active --> Inactive
    Inactive --> [*]

    classDef badState fill:#f00,color:white
    classDef goodState fill:#0f0

    class Active goodState
    class Inactive badState
```

## Pie Chart Styling

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {
    'pie1': '#ff6b6b',
    'pie2': '#4ecdc4',
    'pie3': '#45b7d1',
    'pie4': '#96ceb4',
    'pieStrokeColor': '#333',
    'pieStrokeWidth': '2px',
    'pieTitleTextSize': '20px',
    'pieTitleTextColor': '#333',
    'pieSectionTextSize': '14px',
    'pieSectionTextColor': '#fff',
    'pieLegendTextSize': '14px',
    'pieLegendTextColor': '#333'
}}}%%
pie
    title Distribution
    "A" : 40
    "B" : 30
    "C" : 20
    "D" : 10
```

## Git Graph Styling

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {
    'git0': '#ff6b6b',
    'git1': '#4ecdc4',
    'git2': '#45b7d1',
    'git3': '#96ceb4',
    'gitBranchLabel0': '#fff',
    'gitBranchLabel1': '#fff',
    'commitLabelColor': '#fff',
    'commitLabelBackground': '#333'
}}}%%
gitGraph
    commit
    branch develop
    commit
    checkout main
    commit
```

## Gantt Chart Styling

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {
    'todayLineColor': '#f00',
    'taskBkgColor': '#4ecdc4',
    'taskBorderColor': '#333',
    'taskTextColor': '#fff',
    'taskTextDarkColor': '#333',
    'taskTextLightColor': '#fff',
    'sectionBkgColor': '#f9f9f9',
    'sectionBkgColor2': '#eee',
    'gridColor': '#ddd',
    'doneTaskBkgColor': '#96ceb4',
    'activeTaskBkgColor': '#ff6b6b',
    'critBkgColor': '#f00',
    'critBorderColor': '#a00'
}}}%%
gantt
    title Styled Gantt
    dateFormat YYYY-MM-DD
    section Tasks
    Task 1 :done, 2024-01-01, 5d
    Task 2 :active, 2024-01-06, 5d
    Task 3 :crit, 2024-01-11, 5d
```

## Flowchart Configuration

```mermaid
%%{init: {'flowchart': {
    'curve': 'basis',
    'padding': 15,
    'nodeSpacing': 50,
    'rankSpacing': 50,
    'htmlLabels': true,
    'useMaxWidth': true
}}}%%
flowchart LR
    A --> B --> C
```

### Curve Options

- `basis` - Smooth curves
- `linear` - Straight lines
- `cardinal` - Cardinal splines
- `monotoneX` - Monotonic in x
- `monotoneY` - Monotonic in y
- `natural` - Natural splines
- `step` - Step function
- `stepAfter` - Step after point
- `stepBefore` - Step before point

## Font Configuration

```mermaid
%%{init: {
    'themeVariables': {
        'fontFamily': 'arial',
        'fontSize': '16px'
    }
}}%%
flowchart LR
    A[Custom Font] --> B[Example]
```

## Security Configuration

```javascript
mermaid.initialize({
  securityLevel: 'strict', // strict, loose, antiscript, sandbox
  startOnLoad: true
});
```

Security levels:

- `strict` - Tags encoded, click disabled
- `loose` - Tags allowed, click enabled
- `antiscript` - Script tags disabled
- `sandbox` - Iframe sandbox mode

## Accessibility

### ARIA Labels

Add descriptions for screen readers:

```mermaid
flowchart LR
    A --> B

    accTitle: Simple flow diagram
    accDescr: Shows the relationship between A and B
```

### Title and Description

```mermaid
---
title: My Diagram
---
flowchart LR
    A --> B
```

## Best Practices

1. **Consistency** - Use the same theme across related diagrams
2. **Contrast** - Ensure sufficient contrast for readability
3. **Semantics** - Use colors meaningfully (red for errors, green for success)
4. **Simplicity** - Don't over-style; clarity comes first
5. **Accessibility** - Test with colorblind-friendly palettes
6. **Documentation** - Comment your style choices

## Common Issues

### Styles Not Applying

- Check syntax (no trailing commas in JSON)
- Ensure `%%{init:` is at the very start
- Verify theme variable names are correct

### Colors Not Showing

- Use valid hex colors (`#ff6b6b`)
- Check for typos in variable names
- Some variables require specific diagram types

### Font Issues

- Use web-safe fonts or ensure font is loaded
- Check `fontFamily` is quoted if contains spaces
