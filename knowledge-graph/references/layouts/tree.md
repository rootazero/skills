# tree

Left-to-right branching structure for sequential content.

## Graph Direction

- Primary: Left to Right (LR)
- Shows progression and flow

## Visual Characteristics

- Start point on left, end on right
- Sequential steps connected horizontally
- Branches for alternatives or sub-processes
- Timeline-like appearance

## Mermaid Template

```mermaid
graph LR
    classDef start fill:#27AE60,stroke:#1E8449,color:#fff
    classDef process fill:#3498DB,stroke:#2980B9,color:#fff
    classDef decision fill:#F39C12,stroke:#D68910,color:#fff
    classDef end fill:#E74C3C,stroke:#C0392B,color:#fff

    A[Start]:::start --> B[Step 1]:::process
    B --> C{Decision}:::decision
    C -->|Yes| D[Step 2A]:::process
    C -->|No| E[Step 2B]:::process
    D --> F[Step 3]:::process
    E --> F
    F --> G[End]:::end
```

## Timeline Variant

```mermaid
graph LR
    subgraph Phase1["Phase 1"]
        A[Task A] --> B[Task B]
    end

    subgraph Phase2["Phase 2"]
        C[Task C] --> D[Task D]
    end

    subgraph Phase3["Phase 3"]
        E[Task E] --> F[Task F]
    end

    Phase1 --> Phase2
    Phase2 --> Phase3
```

## Node Limits

- Max steps in main path: 10
- Max branches per decision: 3
- Max parallel paths: 4

## Best For

- Process documentation
- Workflow guides
- Historical timelines
- Decision trees
- User journey maps
- Tutorial step sequences
