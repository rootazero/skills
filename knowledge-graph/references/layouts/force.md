# force

Physics-based clustering where related concepts group naturally.

## Graph Direction

- No fixed direction
- Nodes cluster by relationship density
- Organic, network-like appearance

## Visual Characteristics

- Highly connected nodes pull together
- Loosely connected nodes drift apart
- Natural groupings emerge
- Shows interconnection complexity

## Mermaid Template

```mermaid
graph LR
    classDef primary fill:#9B59B6,stroke:#8E44AD,color:#fff
    classDef secondary fill:#1ABC9C,stroke:#16A085,color:#fff
    classDef tertiary fill:#F39C12,stroke:#D68910,color:#fff

    A[Concept A]:::primary --- B[Concept B]:::primary
    A --- C[Concept C]:::secondary
    B --- C
    B --- D[Concept D]:::secondary
    C --- E[Concept E]:::tertiary
    D --- E
    D --- F[Concept F]:::tertiary
    E --- F
    A -.-> G[Related Topic]:::tertiary
```

## DOT Template (Better for Force Layout)

```dot
graph KnowledgeNetwork {
    layout=neato;
    overlap=false;
    splines=true;

    node [shape=ellipse, style=filled, fillcolor="#E8E8E8"];

    A [label="Concept A", fillcolor="#9B59B6", fontcolor="white"];
    B [label="Concept B", fillcolor="#9B59B6", fontcolor="white"];
    C [label="Concept C"];

    A -- B [weight=2];
    A -- C [weight=1];
    B -- C [weight=1];
}
```

## Node Limits

- Max nodes: 30-40 for readability
- Connections should be meaningful, not exhaustive
- Group dense clusters with visual styling

## Best For

- Complex systems with many interdependencies
- Research papers with cross-references
- Technical architectures
- Social network analysis
- Ecosystem or market analysis
