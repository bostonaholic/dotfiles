# Class Diagrams

Class diagrams model object-oriented structures showing classes, attributes,
methods, and relationships.

## Basic Syntax

```mermaid
classDiagram
    class Animal {
        +String name
        +int age
        +makeSound()
    }
```

## Class Definition

### Attributes and Methods

```mermaid
classDiagram
    class BankAccount {
        +String owner
        +BigDecimal balance
        +deposit(amount)
        +withdraw(amount)
        +getBalance() BigDecimal
    }
```

### Visibility Modifiers

- `+` Public
- `-` Private
- `#` Protected
- `~` Package/Internal

```mermaid
classDiagram
    class Example {
        +publicAttr
        -privateAttr
        #protectedAttr
        ~packageAttr
        +publicMethod()
        -privateMethod()
    }
```

### Generic Types

```mermaid
classDiagram
    class List~T~ {
        +add(T item)
        +get(int index) T
    }
```

### Abstract Classes and Methods

```mermaid
classDiagram
    class Animal {
        <<abstract>>
        +String name
        +makeSound()* void
    }
```

### Interfaces

```mermaid
classDiagram
    class Flyable {
        <<interface>>
        +fly() void
    }
```

### Other Annotations

```mermaid
classDiagram
    class Service {
        <<service>>
    }
    class Utility {
        <<enumeration>>
        RED
        GREEN
        BLUE
    }
```

## Relationships

### Inheritance (Extends)

```mermaid
classDiagram
    Animal <|-- Dog
    Animal <|-- Cat
```

### Composition (Strong "has-a")

```mermaid
classDiagram
    Car *-- Engine
    Car *-- Wheel
```

### Aggregation (Weak "has-a")

```mermaid
classDiagram
    Department o-- Employee
```

### Association

```mermaid
classDiagram
    Student --> Course
```

### Dependency

```mermaid
classDiagram
    Client ..> Service
```

### Realization (Implements)

```mermaid
classDiagram
    Flyable <|.. Bird
```

### All Relationship Types

```mermaid
classDiagram
    classA <|-- classB : Inheritance
    classC *-- classD : Composition
    classE o-- classF : Aggregation
    classG --> classH : Association
    classI -- classJ : Link (solid)
    classK ..> classL : Dependency
    classM <|.. classN : Realization
    classO .. classP : Link (dashed)
```

## Cardinality/Multiplicity

```mermaid
classDiagram
    Customer "1" --> "*" Order : places
    Order "1" --> "1..*" LineItem : contains
    Product "0..1" --> "0..*" Review : has
```

Common multiplicities:

- `1` - Exactly one
- `0..1` - Zero or one
- `1..*` - One or more
- `*` - Zero or more (same as `0..*`)
- `n` - Specific number
- `0..n` - Zero to n

## Labels

```mermaid
classDiagram
    classA --|> classB : implements
    classC --* classD : composition
    classE --o classF : aggregation
```

## Namespaces

```mermaid
classDiagram
    namespace Models {
        class User
        class Product
    }
    namespace Services {
        class UserService
        class ProductService
    }
    UserService --> User
    ProductService --> Product
```

## Notes

```mermaid
classDiagram
    class Animal
    note for Animal "This is a note\nfor the Animal class"
```

General notes:

```mermaid
classDiagram
    note "General diagram note"
    class Animal
```

## Direction

```mermaid
classDiagram
    direction RL
    class A
    class B
    A --> B
```

Options: `TB`, `BT`, `LR`, `RL`

## Styling

### Class Styling

```mermaid
classDiagram
    class Animal
    class Mammal
    Animal <|-- Mammal

    style Animal fill:#f9f,stroke:#333,stroke-width:4px
    style Mammal fill:#bbf,stroke:#f66,stroke-width:2px
```

### CSS Classes

```mermaid
classDiagram
    class Animal:::highlight
    classDef highlight fill:#ff0,stroke:#000
```

## Complete Example

```mermaid
classDiagram
    class Animal {
        <<abstract>>
        +String name
        +int age
        +makeSound()* void
        +move() void
    }

    class Dog {
        +String breed
        +makeSound() void
        +fetch() void
    }

    class Cat {
        +boolean indoor
        +makeSound() void
        +scratch() void
    }

    class Pet {
        <<interface>>
        +play() void
    }

    Animal <|-- Dog
    Animal <|-- Cat
    Pet <|.. Dog
    Pet <|.. Cat

    class Owner {
        +String name
        +adopt(Pet pet) void
    }

    Owner "1" --> "*" Pet : owns
```

## Best Practices

1. Use meaningful class and method names
2. Show only relevant attributes and methods
3. Use proper visibility modifiers
4. Group related classes with namespaces
5. Add cardinality to clarify relationships
6. Use notes to explain complex logic
7. Keep diagrams focused on one aspect of the system

## Common Patterns

### Repository Pattern

```mermaid
classDiagram
    class Repository~T~ {
        <<interface>>
        +findById(id) T
        +findAll() List~T~
        +save(T entity) T
        +delete(id) void
    }

    class UserRepository {
        +findByEmail(email) User
    }

    Repository~User~ <|.. UserRepository
```

### Factory Pattern

```mermaid
classDiagram
    class Product {
        <<interface>>
        +use() void
    }
    class ConcreteProductA {
        +use() void
    }
    class ConcreteProductB {
        +use() void
    }
    class Factory {
        <<interface>>
        +create() Product
    }
    class ConcreteFactory {
        +create() Product
    }

    Product <|.. ConcreteProductA
    Product <|.. ConcreteProductB
    Factory <|.. ConcreteFactory
    ConcreteFactory ..> Product
```

### MVC Pattern

```mermaid
classDiagram
    class Model {
        +data
        +getData()
        +setData()
    }
    class View {
        +render()
        +getUserInput()
    }
    class Controller {
        +handleRequest()
        +updateModel()
        +updateView()
    }

    Controller --> Model
    Controller --> View
    View ..> Model
```
