# Mind Maps

Mind maps visualize hierarchical information radiating from a central concept.

## Basic Syntax

```mermaid
mindmap
    root((Central Idea))
        Topic 1
            Subtopic 1.1
            Subtopic 1.2
        Topic 2
            Subtopic 2.1
        Topic 3
```

## Node Shapes

```mermaid
mindmap
    root((Circle - root))
        (Rounded rectangle)
            [Rectangle/square]
                ))Cloud((
                    {{Hexagon}}
                        )Bang(
```

Shape syntax:

- `((text))` - Circle (typically for root)
- `(text)` - Rounded rectangle
- `[text]` - Square/rectangle
- `))text((` - Cloud
- `{{text}}` - Hexagon
- `)text(` - Bang/explosion

## Hierarchy

Indentation defines the hierarchy:

```mermaid
mindmap
    root((Project))
        Planning
            Requirements
            Design
            Timeline
        Development
            Frontend
                React
                CSS
            Backend
                API
                Database
        Testing
            Unit Tests
            Integration
```

## Icons

Add Font Awesome icons:

```mermaid
mindmap
    root((fa:fa-book Documentation))
        fa:fa-file Guides
        fa:fa-code API Reference
        fa:fa-users Community
```

Common icons:

- `fa:fa-home` - Home
- `fa:fa-user` - User
- `fa:fa-cog` - Settings
- `fa:fa-check` - Check
- `fa:fa-star` - Star
- `fa:fa-heart` - Heart
- `fa:fa-folder` - Folder
- `fa:fa-file` - File

## Markdown in Nodes

```mermaid
mindmap
    root(Main Topic)
        **Bold text**
        *Italic text*
```

## Complete Examples

### Project Planning

```mermaid
mindmap
    root((Project Launch))
        Research
            Market Analysis
            Competitor Review
            User Interviews
        Design
            Wireframes
            Prototypes
            User Testing
        Development
            Frontend
                React Components
                Styling
            Backend
                API Design
                Database
        Launch
            Marketing
            Documentation
            Support
```

### Learning Path

```mermaid
mindmap
    root((Web Development))
        Frontend
            HTML
                Semantic HTML
                Accessibility
            CSS
                Flexbox
                Grid
                Animations
            JavaScript
                ES6+
                DOM
                Async
        Backend
            Node.js
            Python
            Databases
                SQL
                NoSQL
        DevOps
            Git
            CI/CD
            Cloud
                AWS
                Azure
```

### Meeting Notes

```mermaid
mindmap
    root((Q4 Planning))
        Goals
            Increase revenue 20%
            Launch 2 new features
            Improve NPS score
        Challenges
            Limited resources
            Technical debt
            Market competition
        Action Items
            Hire 3 engineers
            Prioritize roadmap
            Customer feedback sessions
        Timeline
            October: Planning
            November: Development
            December: Launch
```

### Problem Solving

```mermaid
mindmap
    root((Slow Page Load))
        Frontend
            Large bundle size
                Code splitting
                Tree shaking
            Unoptimized images
                Compression
                Lazy loading
            Too many requests
                Bundling
                Caching
        Backend
            Slow queries
                Add indexes
                Query optimization
            No caching
                Redis
                CDN
        Network
            No compression
            Far server
                CDN
                Edge locations
```

### Decision Tree

```mermaid
mindmap
    root((Choose Framework))
        React
            Pros
                Large ecosystem
                Job market
                Flexibility
            Cons
                Learning curve
                Boilerplate
        Vue
            Pros
                Easy to learn
                Good docs
                Progressive
            Cons
                Smaller ecosystem
        Angular
            Pros
                Full framework
                TypeScript
                Enterprise ready
            Cons
                Complex
                Opinionated
```

## Styling

### Theme Configuration

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {
    'primaryColor': '#ff6b6b',
    'primaryTextColor': '#fff',
    'primaryBorderColor': '#ff5252'
}}}%%
mindmap
    root((Styled))
        Branch 1
        Branch 2
```

## Best Practices

1. Keep the central idea concise and clear
2. Use consistent indentation (2 or 4 spaces)
3. Limit depth to 3-4 levels for readability
4. Use shapes strategically to highlight important nodes
5. Add icons for visual recognition
6. Group related concepts together
7. Keep node text brief

## Limitations

- No custom colors per branch
- Limited styling options
- No connection lines between non-adjacent nodes
- Icons require Font Awesome
- Cannot control layout direction

## When to Use Mind Maps

Good for:

- Brainstorming and ideation
- Organizing hierarchical information
- Note-taking and summarization
- Planning and outlining
- Visualizing relationships

Avoid when:

- Showing sequential processes (use flowchart)
- Precise relationships matter (use class diagram)
- Data has many cross-connections (use flowchart with links)
