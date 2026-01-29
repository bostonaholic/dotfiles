# Pie Charts

Pie charts show proportional data as slices of a circle.

## Basic Syntax

```mermaid
pie
    title Browser Market Share
    "Chrome" : 65
    "Safari" : 19
    "Firefox" : 10
    "Edge" : 6
```

## Configuration

### Title

```mermaid
pie
    title My Pie Chart
    "A" : 30
    "B" : 70
```

### Show Data

Display values on the chart:

```mermaid
pie showData
    title Budget Allocation
    "Development" : 45
    "Marketing" : 25
    "Operations" : 20
    "Other" : 10
```

## Data Format

Each slice is defined as:

```text
"Label" : value
```

Values can be integers or decimals. The chart automatically calculates percentages.

```mermaid
pie
    title Response Times
    "< 100ms" : 42.5
    "100-500ms" : 35.2
    "> 500ms" : 22.3
```

## Complete Examples

### Project Time Distribution

```mermaid
pie showData
    title Time Spent on Project Phases
    "Planning" : 10
    "Development" : 45
    "Testing" : 25
    "Documentation" : 10
    "Deployment" : 10
```

### Survey Results

```mermaid
pie
    title Customer Satisfaction
    "Very Satisfied" : 45
    "Satisfied" : 30
    "Neutral" : 15
    "Dissatisfied" : 7
    "Very Dissatisfied" : 3
```

### Resource Allocation

```mermaid
pie showData
    title Team Allocation by Department
    "Engineering" : 12
    "Product" : 4
    "Design" : 3
    "QA" : 5
    "DevOps" : 2
```

### Budget Breakdown

```mermaid
pie
    title Annual Budget 2024
    "Salaries" : 55
    "Infrastructure" : 20
    "Marketing" : 15
    "R&D" : 7
    "Other" : 3
```

## Styling

### Theme Configuration

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {
    'pie1': '#ff6b6b',
    'pie2': '#4ecdc4',
    'pie3': '#45b7d1',
    'pie4': '#96ceb4',
    'pie5': '#ffeaa7',
    'pie6': '#dfe6e9',
    'pie7': '#74b9ff',
    'pieStrokeWidth': '2px',
    'pieLegendTextSize': '14px'
}}}%%
pie
    title Custom Colors
    "Red" : 20
    "Teal" : 20
    "Blue" : 20
    "Green" : 20
    "Yellow" : 10
    "Gray" : 10
```

### Available Theme Variables

- `pie1` through `pie12` - Slice colors
- `pieStrokeColor` - Border color
- `pieStrokeWidth` - Border width
- `pieOpacity` - Slice opacity
- `pieLegendTextSize` - Legend font size
- `pieLegendTextColor` - Legend text color
- `pieTitleTextColor` - Title color
- `pieTitleTextSize` - Title font size
- `pieSectionTextSize` - Label font size
- `pieSectionTextColor` - Label color

## Best Practices

1. Limit to 5-7 slices for readability
2. Use meaningful labels
3. Order slices by size (largest first) or logically
4. Use `showData` when exact values matter
5. Consider using a bar chart for many categories
6. Use contrasting colors for adjacent slices
7. Include a descriptive title

## Limitations

- No interactive features
- Limited customization of individual slices
- No doughnut chart variant
- Labels may overlap with many slices
- Percentages auto-calculated (cannot override display)

## When to Use Pie Charts

Good for:

- Showing parts of a whole
- Comparing proportions at a glance
- Simple distributions with few categories

Avoid when:

- Comparing values precisely
- Showing changes over time
- Many categories (use bar chart)
- Values don't sum to a meaningful total
