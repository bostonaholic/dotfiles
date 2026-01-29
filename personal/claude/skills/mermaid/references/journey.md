# User Journey Diagrams

User journey diagrams illustrate the steps users take to complete tasks,
showing satisfaction levels and actors involved.

## Basic Syntax

```mermaid
journey
    title My Working Day
    section Go to work
        Make tea: 5: Me
        Go upstairs: 3: Me
        Do work: 1: Me, Cat
    section Go home
        Go downstairs: 5: Me
        Sit down: 5: Me
```

## Structure

### Title

```mermaid
journey
    title User Onboarding Experience
```

### Sections

Sections group related tasks:

```mermaid
journey
    title Shopping Experience
    section Discovery
        Browse homepage: 4: Customer
        Search products: 3: Customer
    section Purchase
        Add to cart: 5: Customer
        Checkout: 2: Customer
```

### Tasks

Task syntax:

```text
Task name: score: actor1, actor2
```

- **Task name** - Description of the step
- **Score** - Satisfaction level (1-5)
  - 5 = Very positive (green)
  - 4 = Positive
  - 3 = Neutral (yellow)
  - 2 = Negative
  - 1 = Very negative (red)
- **Actors** - Comma-separated list of participants

## Complete Examples

### E-commerce User Journey

```mermaid
journey
    title Online Shopping Journey
    section Discovery
        Visit website: 5: Customer
        Browse categories: 4: Customer
        Search for product: 3: Customer
        View product details: 4: Customer
    section Decision
        Read reviews: 4: Customer
        Compare prices: 3: Customer
        Check availability: 5: Customer
    section Purchase
        Add to cart: 5: Customer
        Enter shipping info: 2: Customer
        Enter payment: 2: Customer
        Confirm order: 4: Customer
    section Post-Purchase
        Receive confirmation: 5: Customer
        Track shipment: 4: Customer
        Receive delivery: 5: Customer, Delivery
        Leave review: 3: Customer
```

### SaaS Onboarding

```mermaid
journey
    title SaaS Onboarding Experience
    section Sign Up
        Discover product: 4: Prospect
        Visit pricing page: 3: Prospect
        Start free trial: 5: Prospect
        Create account: 4: New User
    section Setup
        Verify email: 3: New User
        Complete profile: 2: New User
        Connect integrations: 2: New User, Support
        Import data: 1: New User, Support
    section Activation
        Complete tutorial: 4: New User
        Create first project: 5: New User
        Invite team members: 3: New User, Admin
    section Conversion
        Reach usage limit: 2: User
        Review plans: 3: User
        Upgrade account: 4: User, Sales
        Setup billing: 3: User
```

### Support Ticket Journey

```mermaid
journey
    title Customer Support Journey
    section Issue Discovery
        Encounter problem: 1: Customer
        Search knowledge base: 2: Customer
        Fail to find solution: 1: Customer
    section Contact Support
        Submit ticket: 3: Customer
        Receive auto-reply: 4: Customer
        Wait for response: 2: Customer
    section Resolution
        Receive initial response: 4: Customer, Agent
        Provide more details: 3: Customer
        Agent investigates: 3: Agent
        Solution provided: 5: Customer, Agent
    section Follow-up
        Confirm resolution: 5: Customer
        Rate experience: 4: Customer
        Receive survey: 3: Customer
```

### Mobile App First Use

```mermaid
journey
    title First Time App User Journey
    section Download
        See app store listing: 4: User
        Read reviews: 3: User
        Download app: 5: User
    section Onboarding
        Open app: 5: User
        View welcome screens: 3: User
        Skip tutorial: 4: User
        Grant permissions: 2: User
    section First Use
        Explore main screen: 4: User
        Try core feature: 5: User
        Encounter error: 1: User
        Contact support: 2: User, Support
    section Retention
        Receive push notification: 3: User
        Return next day: 4: User
        Complete key action: 5: User
```

### Employee Onboarding

```mermaid
journey
    title New Employee Onboarding
    section Pre-Start
        Receive offer: 5: New Hire
        Complete paperwork: 2: New Hire, HR
        Receive welcome email: 4: New Hire
    section Day One
        Arrive at office: 4: New Hire
        Meet team: 5: New Hire, Team
        Setup workstation: 2: New Hire, IT
        Complete HR training: 2: New Hire
    section First Week
        Team lunch: 5: New Hire, Team
        Learn tools: 3: New Hire, Mentor
        First task assignment: 4: New Hire, Manager
        Daily check-ins: 4: New Hire, Mentor
    section First Month
        Complete training: 3: New Hire
        First project: 4: New Hire, Team
        Performance check-in: 4: New Hire, Manager
        Feel productive: 5: New Hire
```

### Healthcare Patient Journey

```mermaid
journey
    title Patient Appointment Journey
    section Booking
        Feel unwell: 1: Patient
        Call clinic: 2: Patient
        Book appointment: 3: Patient, Receptionist
        Receive confirmation: 4: Patient
    section Pre-Visit
        Fill forms online: 2: Patient
        Receive reminder: 4: Patient
        Travel to clinic: 3: Patient
    section Visit
        Check in: 4: Patient, Receptionist
        Wait in lobby: 2: Patient
        See doctor: 4: Patient, Doctor
        Receive diagnosis: 3: Patient, Doctor
        Get prescription: 4: Patient, Doctor
    section Post-Visit
        Schedule follow-up: 3: Patient, Receptionist
        Pick up medication: 4: Patient, Pharmacist
        Start treatment: 3: Patient
        Recovery: 5: Patient
```

## Styling

### Theme Configuration

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {
    'primaryColor': '#326ce5',
    'primaryTextColor': '#fff'
}}}%%
journey
    title Styled Journey
    section Phase 1
        Task A: 5: User
        Task B: 3: User
```

## Best Practices

1. Use descriptive task names
2. Be honest with satisfaction scores
3. Include all relevant actors
4. Group logical steps into sections
5. Keep journeys focused on one persona/goal
6. Use consistent scoring criteria
7. Include both positive and negative moments
8. Identify pain points (low scores) for improvement

## Interpreting Results

- **Consecutive low scores** - Major pain point requiring attention
- **Score drops** - Friction points in the journey
- **Multiple actors** - Handoff points (often problematic)
- **Long sections** - May need to be broken down

## When to Use User Journeys

Good for:

- Mapping customer experiences
- Identifying pain points
- Planning service improvements
- Onboarding documentation
- Stakeholder communication
- UX research visualization

Avoid when:

- Need to show system architecture (use architecture diagram)
- Mapping complex workflows (use flowchart)
- Showing data flow (use sequence diagram)
