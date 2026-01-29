# Timeline Diagrams

Timeline diagrams show events arranged chronologically.

## Basic Syntax

```mermaid
timeline
    title History of Web Development
    1991 : HTML invented
    1995 : JavaScript created
    1996 : CSS introduced
    2004 : Web 2.0 era begins
    2010 : HTML5 released
```

## Title and Sections

```mermaid
timeline
    title Company Milestones
    section 2020
        January : Company founded
        June : First product launch
    section 2021
        March : Series A funding
        October : 100 employees
    section 2022
        February : International expansion
        December : IPO
```

## Multiple Events Per Period

```mermaid
timeline
    title Q1 2024 Releases
    January : Feature A
            : Bug fix B
            : Security patch
    February : Feature C
             : Performance update
    March : Major release v2.0
```

## Complete Examples

### Product Roadmap

```mermaid
timeline
    title Product Roadmap 2024
    section Q1
        January : User authentication revamp
                : Dashboard redesign
        February : API v2 launch
        March : Mobile app beta
    section Q2
        April : Mobile app launch
              : Analytics integration
        May : Team collaboration features
        June : Enterprise tier
    section Q3
        July : AI-powered insights
        August : Custom integrations
        September : Performance optimization
    section Q4
        October : Multi-language support
        November : Advanced reporting
        December : Year-end review
```

### Project Timeline

```mermaid
timeline
    title Website Redesign Project
    section Discovery
        Week 1-2 : Stakeholder interviews
                 : User research
                 : Competitive analysis
    section Design
        Week 3-4 : Wireframes
                 : Design system
        Week 5-6 : High-fidelity mockups
                 : Prototype
    section Development
        Week 7-10 : Frontend development
                  : Backend integration
        Week 11-12 : Testing & QA
    section Launch
        Week 13 : Soft launch
                : Monitoring
        Week 14 : Full launch
                : Documentation
```

### Historical Timeline

```mermaid
timeline
    title Evolution of Programming Languages
    1950s : Fortran (1957)
          : LISP (1958)
    1960s : COBOL (1960)
          : BASIC (1964)
    1970s : C (1972)
          : SQL (1974)
    1980s : C++ (1983)
          : Perl (1987)
    1990s : Python (1991)
          : Java (1995)
          : JavaScript (1995)
          : PHP (1995)
    2000s : C# (2000)
          : Go (2009)
    2010s : Rust (2010)
          : TypeScript (2012)
          : Swift (2014)
```

### Sprint Timeline

```mermaid
timeline
    title Sprint 15 Timeline
    section Planning
        Day 1 : Sprint planning
              : Task breakdown
    section Development
        Day 2-3 : User story US-101
        Day 4-5 : User story US-102
        Day 6-7 : Bug fixes
    section Testing
        Day 8-9 : QA testing
                : Bug resolution
    section Review
        Day 10 : Sprint demo
               : Retrospective
```

### Release History

```mermaid
timeline
    title Version Release History
    section v1.x
        v1.0 : Initial release
             : Core features
        v1.1 : Bug fixes
             : Performance improvements
        v1.2 : New dashboard
    section v2.x
        v2.0 : Major redesign
             : New API
             : Breaking changes
        v2.1 : Additional integrations
        v2.2 : Security updates
    section v3.x
        v3.0 : AI features
             : Real-time sync
```

## Styling

### Theme Configuration

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {
    'cScale0': '#ff6b6b',
    'cScale1': '#4ecdc4',
    'cScale2': '#45b7d1'
}}}%%
timeline
    title Styled Timeline
    2020 : Event 1
    2021 : Event 2
    2022 : Event 3
```

### Available Theme Variables

- `cScale0` through `cScale11` - Section background colors
- `cScaleLabel0` through `cScaleLabel11` - Section label colors
- `cScalePeer1` - Alternative color scheme

## Best Practices

1. Use clear, concise event descriptions
2. Group related events into sections
3. Maintain chronological order
4. Use consistent time period formats
5. Keep the timeline focused on one topic
6. Limit events per period for readability
7. Use descriptive section titles

## Limitations

- Limited styling per event
- No custom icons or images
- Cannot show overlapping events
- No duration visualization
- Simple vertical layout only

## When to Use Timeline Diagrams

Good for:

- Historical events
- Project milestones
- Release history
- Roadmaps
- Process phases
- Sprint planning

Avoid when:

- Showing complex dependencies (use Gantt)
- Overlapping time periods
- Detailed task scheduling
- Resource allocation
