# hierarchical

Top-down tree structure with clear parent-child relationships.

## Graph Direction

- Primary: Top to Bottom (TB)
- Alternative: Left to Right (LR) for wide content

## Visual Characteristics

- Root node at top, children below
- Levels aligned horizontally
- Clear vertical flow of information
- Subgraphs for chapter grouping

## Mermaid Template

```mermaid
graph TD
    classDef chapter fill:#4A90D9,stroke:#2E5A8B,color:#fff,font-weight:bold
    classDef concept fill:#F5F5F5,stroke:#999,color:#333
    classDef detail fill:#fff,stroke:#ccc,color:#666,font-size:12px

    subgraph Ch1["Chapter Title"]
        A[Core Concept]:::concept --> B[Sub Concept 1]:::concept
        A --> C[Sub Concept 2]:::concept
        B --> D[Detail]:::detail
    end
```

## Node Limits

- Max depth: 4 levels
- Max nodes per level: 6
- Max total nodes per chapter: 20

## Best For

- Textbooks with clear chapter structure
- Tutorial content with prerequisites
- API documentation
- Organizational hierarchies
- Taxonomies and classifications
