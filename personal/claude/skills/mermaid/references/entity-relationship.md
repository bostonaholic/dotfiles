# Entity Relationship Diagrams (ERD)

ER diagrams model database schemas showing entities, attributes, and relationships.

## Basic Syntax

```mermaid
erDiagram
    CUSTOMER ||--o{ ORDER : places
    ORDER ||--|{ LINE-ITEM : contains
    PRODUCT ||--o{ LINE-ITEM : "is in"
```

## Entities

Entities are defined implicitly through relationships or with attributes:

```mermaid
erDiagram
    CUSTOMER {
        int id PK
        string name
        string email UK
    }
```

## Attributes

### Attribute Types

```mermaid
erDiagram
    ENTITY {
        type name
        type name PK
        type name FK
        type name UK
    }
```

- `PK` - Primary Key
- `FK` - Foreign Key
- `UK` - Unique Key

### Common Types

```mermaid
erDiagram
    PRODUCT {
        int id PK
        string name
        string description
        decimal price
        int quantity
        date created_at
        boolean active
    }
```

### Attribute Comments

```mermaid
erDiagram
    USER {
        int id PK "Auto-generated"
        string email UK "Must be valid email"
        string password "Hashed with bcrypt"
    }
```

## Relationships

### Relationship Syntax

`Entity1 <cardinality1>--<cardinality2> Entity2 : "label"`

### Cardinality Notation

Left side of `--`:

- `|o` - Zero or one
- `||` - Exactly one
- `}o` - Zero or more
- `}|` - One or more

Right side of `--`:

- `o|` - Zero or one
- `||` - Exactly one
- `o{` - Zero or more
- `|{` - One or more

### Relationship Types

```mermaid
erDiagram
    A ||--|| B : "one to one"
    C ||--o{ D : "one to zero or more"
    E ||--|{ F : "one to one or more"
    G }o--o{ H : "zero or more to zero or more"
```

### All Cardinality Combinations

| Left | Right | Meaning |
| --- | --- | --- |
| `\|o` | `o\|` | Zero or one to zero or one |
| `\|o` | `\|\|` | Zero or one to exactly one |
| `\|o` | `o{` | Zero or one to zero or more |
| `\|o` | `\|{` | Zero or one to one or more |
| `\|\|` | `o\|` | Exactly one to zero or one |
| `\|\|` | `\|\|` | Exactly one to exactly one |
| `\|\|` | `o{` | Exactly one to zero or more |
| `\|\|` | `\|{` | Exactly one to one or more |
| `}o` | `o\|` | Zero or more to zero or one |
| `}o` | `\|\|` | Zero or more to exactly one |
| `}o` | `o{` | Zero or more to zero or more |
| `}o` | `\|{` | Zero or more to one or more |
| `}\|` | `o\|` | One or more to zero or one |
| `}\|` | `\|\|` | One or more to exactly one |
| `}\|` | `o{` | One or more to zero or more |
| `}\|` | `\|{` | One or more to one or more |

### Identifying vs Non-Identifying

```mermaid
erDiagram
    PARENT ||--o{ CHILD : "identifying (solid)"
    PARENT2 ||..o{ CHILD2 : "non-identifying (dotted)"
```

- Solid line `--` = Identifying relationship (child depends on parent for identity)
- Dotted line `..` = Non-identifying relationship (child has independent identity)

## Relationship Labels

```mermaid
erDiagram
    CUSTOMER ||--o{ ORDER : places
    ORDER ||--|{ LINE-ITEM : contains
    EMPLOYEE ||--o{ ORDER : handles
    PRODUCT ||--o{ LINE-ITEM : "is ordered in"
```

Use quotes for labels with spaces.

## Complete Examples

### E-Commerce Database

```mermaid
erDiagram
    CUSTOMER {
        int id PK
        string email UK
        string name
        string address
        date created_at
    }

    ORDER {
        int id PK
        int customer_id FK
        date order_date
        string status
        decimal total
    }

    LINE_ITEM {
        int id PK
        int order_id FK
        int product_id FK
        int quantity
        decimal unit_price
    }

    PRODUCT {
        int id PK
        string sku UK
        string name
        string description
        decimal price
        int stock_quantity
    }

    CATEGORY {
        int id PK
        string name
        int parent_id FK
    }

    PRODUCT_CATEGORY {
        int product_id FK
        int category_id FK
    }

    CUSTOMER ||--o{ ORDER : places
    ORDER ||--|{ LINE_ITEM : contains
    PRODUCT ||--o{ LINE_ITEM : "is in"
    CATEGORY ||--o{ CATEGORY : "parent of"
    PRODUCT ||--o{ PRODUCT_CATEGORY : "belongs to"
    CATEGORY ||--o{ PRODUCT_CATEGORY : contains
```

### Blog Platform

```mermaid
erDiagram
    USER {
        int id PK
        string username UK
        string email UK
        string password_hash
        datetime created_at
    }

    POST {
        int id PK
        int author_id FK
        string title
        text content
        string status
        datetime published_at
    }

    COMMENT {
        int id PK
        int post_id FK
        int author_id FK
        text content
        datetime created_at
    }

    TAG {
        int id PK
        string name UK
    }

    POST_TAG {
        int post_id FK
        int tag_id FK
    }

    USER ||--o{ POST : writes
    USER ||--o{ COMMENT : writes
    POST ||--o{ COMMENT : has
    POST ||--o{ POST_TAG : has
    TAG ||--o{ POST_TAG : "applied to"
```

### HR System

```mermaid
erDiagram
    EMPLOYEE {
        int id PK
        string first_name
        string last_name
        string email UK
        date hire_date
        decimal salary
        int department_id FK
        int manager_id FK
    }

    DEPARTMENT {
        int id PK
        string name
        int head_id FK
    }

    PROJECT {
        int id PK
        string name
        date start_date
        date end_date
        string status
    }

    ASSIGNMENT {
        int employee_id FK
        int project_id FK
        string role
        date assigned_date
    }

    DEPARTMENT ||--o{ EMPLOYEE : employs
    EMPLOYEE ||--o{ EMPLOYEE : manages
    DEPARTMENT ||--o| EMPLOYEE : "headed by"
    EMPLOYEE ||--o{ ASSIGNMENT : "works on"
    PROJECT ||--o{ ASSIGNMENT : has
```

## Styling

### Entity Styling

```mermaid
%%{init: {'theme': 'base', 'themeVariables': { 'primaryColor': '#ff0000'}}}%%
erDiagram
    CUSTOMER ||--o{ ORDER : places
```

## Best Practices

1. Use singular nouns for entity names (CUSTOMER, not CUSTOMERS)
2. Use SCREAMING_SNAKE_CASE for entity names
3. Include appropriate data types for attributes
4. Mark primary keys (PK), foreign keys (FK), and unique keys (UK)
5. Use meaningful relationship labels
6. Group related entities together visually
7. Keep diagrams focused - split large schemas into domains
8. Use identifying relationships when appropriate
9. Add comments to complex attributes

## Common Patterns

### Many-to-Many with Junction Table

```mermaid
erDiagram
    STUDENT {
        int id PK
        string name
    }
    COURSE {
        int id PK
        string name
    }
    ENROLLMENT {
        int student_id FK
        int course_id FK
        date enrolled_at
        string grade
    }

    STUDENT ||--o{ ENROLLMENT : enrolls
    COURSE ||--o{ ENROLLMENT : has
```

### Self-Referencing Relationship

```mermaid
erDiagram
    EMPLOYEE {
        int id PK
        string name
        int manager_id FK
    }

    EMPLOYEE ||--o{ EMPLOYEE : manages
```

### Polymorphic Association

```mermaid
erDiagram
    COMMENT {
        int id PK
        string commentable_type
        int commentable_id
        text content
    }
    POST {
        int id PK
        string title
    }
    PHOTO {
        int id PK
        string url
    }

    POST ||--o{ COMMENT : has
    PHOTO ||--o{ COMMENT : has
```
