# Sankey Diagrams

Sankey diagrams visualize flow quantities between nodes, where link width
represents magnitude.

## Basic Syntax

```mermaid
sankey-beta

Source A,Target B,100
Source A,Target C,50
Target B,Final D,80
Target C,Final D,30
```

## Format

Sankey diagrams use CSV-like format with three columns:

- **Source** - Starting node
- **Target** - Ending node
- **Value** - Flow magnitude (determines link width)

```mermaid
sankey-beta

%% source,target,value
Electricity,Residential,30
Electricity,Commercial,25
Electricity,Industrial,45
```

## Special Characters

### Commas in Labels

Wrap labels with commas in double quotes:

```mermaid
sankey-beta

"Sales, North",Revenue,100
"Sales, South",Revenue,80
```

### Double Quotes in Labels

Use paired double quotes inside quoted strings:

```mermaid
sankey-beta

"Product ""A""",Sales,50
"Product ""B""",Sales,75
```

### Empty Lines

Empty lines are allowed for visual separation (no commas):

```mermaid
sankey-beta

Source1,Middle,100

Middle,Target1,60
Middle,Target2,40
```

## Complete Examples

### Energy Flow

```mermaid
sankey-beta

Coal,Electricity,500
Natural Gas,Electricity,300
Nuclear,Electricity,200
Renewables,Electricity,150

Electricity,Residential,350
Electricity,Commercial,300
Electricity,Industrial,400
Electricity,Transportation,100

Residential,Lighting,100
Residential,Heating,150
Residential,Appliances,100

Commercial,Lighting,120
Commercial,HVAC,150
Commercial,Equipment,30

Industrial,Motors,250
Industrial,Process Heat,100
Industrial,Other,50
```

### Website Traffic Flow

```mermaid
sankey-beta

Organic Search,Homepage,5000
Paid Search,Homepage,2000
Social Media,Homepage,1500
Direct,Homepage,3000
Referral,Homepage,1000

Homepage,Products,6000
Homepage,Blog,2500
Homepage,About,1000
Homepage,Bounce,3000

Products,Cart,3000
Products,Exit,3000

Cart,Checkout,2000
Cart,Abandoned,1000

Checkout,Purchase,1800
Checkout,Failed,200
```

### Budget Allocation

```mermaid
sankey-beta

Revenue,Gross Profit,800
Revenue,Cost of Goods,200

Gross Profit,Operating Income,500
Gross Profit,Operating Expenses,300

Operating Expenses,Salaries,150
Operating Expenses,Marketing,80
Operating Expenses,Rent,40
Operating Expenses,Utilities,30

Operating Income,Net Income,400
Operating Income,Taxes,100

Net Income,Reinvestment,250
Net Income,Dividends,150
```

### User Journey Conversion

```mermaid
sankey-beta

Visitors,Signed Up,1000
Visitors,Left,4000

Signed Up,Activated,600
Signed Up,Inactive,400

Activated,Subscribed,300
Activated,Free Tier,300

Subscribed,Monthly,200
Subscribed,Annual,100

Monthly,Renewed,150
Monthly,Churned,50

Annual,Renewed,90
Annual,Churned,10
```

### Data Pipeline

```mermaid
sankey-beta

Raw Data,ETL Process,1000

ETL Process,Cleaned Data,800
ETL Process,Rejected,200

Cleaned Data,Data Warehouse,700
Cleaned Data,Data Lake,100

Data Warehouse,Reports,400
Data Warehouse,Dashboards,200
Data Warehouse,ML Models,100

Reports,Email,250
Reports,Portal,150

Dashboards,Executive,100
Dashboards,Operations,100
```

## Configuration

### Via Init Directive

```mermaid
%%{init: {'sankey': {
    'width': 800,
    'height': 400,
    'linkColor': 'gradient',
    'nodeAlignment': 'justify'
}}}%%
sankey-beta

A,B,100
B,C,80
B,D,20
```

### Configuration Options

| Parameter | Default | Description |
| --- | --- | --- |
| `width` | 600 | Diagram width in pixels |
| `height` | 400 | Diagram height in pixels |
| `linkColor` | 'source' | Link coloring method |
| `nodeAlignment` | 'justify' | Node positioning |

### Link Color Options

- `'source'` - Color based on source node
- `'target'` - Color based on target node
- `'gradient'` - Gradient from source to target
- `'#hexcode'` - Specific hex color

```mermaid
%%{init: {'sankey': {'linkColor': 'gradient'}}}%%
sankey-beta

Input,Process,100
Process,Output,80
Process,Waste,20
```

### Node Alignment Options

- `'justify'` - Spread nodes across full height (default)
- `'left'` - Align to left/top
- `'right'` - Align to right/bottom
- `'center'` - Center alignment

## Styling

### Theme Configuration

```mermaid
%%{init: {'theme': 'base'}}%%
sankey-beta

A,B,50
A,C,30
B,D,40
C,D,20
```

## Best Practices

1. Order flows logically (left to right, top to bottom)
2. Use meaningful node labels
3. Keep node names concise
4. Use gradient colors to show flow direction
5. Group related flows together
6. Add empty lines between logical sections
7. Ensure values are proportionally accurate
8. Limit complexity - split large diagrams

## Limitations

- Experimental feature (v10.3.0+)
- CSV format only (no inline styling per node)
- No custom node colors
- No click events or interactivity
- Cannot control node order explicitly
- Limited annotation options

## When to Use Sankey Diagrams

Good for:

- Energy or resource flows
- Budget allocation visualization
- Website user flow analysis
- Process material flows
- Conversion funnels
- Supply chain visualization

Avoid when:

- Showing hierarchical data (use mind map)
- Simple comparisons (use bar chart)
- Time-based data (use line chart)
- Bidirectional flows are important
