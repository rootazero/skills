# radial

Central concept with radiating branches in all directions.

## Graph Direction

- Center-out expansion
- Use mindmap or flowchart with careful positioning

## Visual Characteristics

- Central node is the main topic
- First-level concepts radiate outward
- Details branch from concepts
- Emphasizes the core idea

## Mermaid Template

```mermaid
mindmap
    root((Central Topic))
        Concept A
            Detail A1
            Detail A2
        Concept B
            Detail B1
        Concept C
            Detail C1
            Detail C2
            Detail C3
        Concept D
            Detail D1
```

## Alternative Flowchart Style

```mermaid
graph TD
    classDef center fill:#E74C3C,stroke:#C0392B,color:#fff,font-weight:bold
    classDef branch fill:#3498DB,stroke:#2980B9,color:#fff

    Center((Main Topic)):::center
    Center --> A[Concept A]:::branch
    Center --> B[Concept B]:::branch
    Center --> C[Concept C]:::branch
    Center --> D[Concept D]:::branch
    A --> A1[Detail]
    B --> B1[Detail]
```

## Node Limits

- Max first-level branches: 8
- Max second-level per branch: 5
- Max depth: 3 levels

## Best For

- Single-topic deep exploration
- Brainstorming summaries
- Concept maps around a theme
- Problem-solution analysis
- Feature overview of a product
