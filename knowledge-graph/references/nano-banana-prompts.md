# Image Generation Prompts for Knowledge Graphs

This file contains **image generation prompts** for creating knowledge graph visualizations.

## Supported Image Models

| Model | Default | Notes |
|-------|---------|-------|
| **nano banana** | ✓ | **Recommended** - Best quality for knowledge graphs |
| DALL-E | | OpenAI's image model |
| Midjourney | | High aesthetic quality |
| Stable Diffusion | | Open source, local or API |
| Ideogram | | Good for text rendering in images |

**Detection keywords:**
- nano banana: `nano banana`, `nanobanana`
- DALL-E: `dalle`, `dall-e`, `openai`
- Midjourney: `midjourney`, `mj`
- Stable Diffusion: `sd`, `stable-diffusion`, `stable diffusion`
- Ideogram: `ideogram`

---

## Prompt Structure for Knowledge Graph Images

A good knowledge graph image prompt must include:

1. **Visual style** - Clean, professional diagram style
2. **Layout type** - Hierarchical, radial, network, etc.
3. **Entities** - Nodes with labels and types
4. **Relationships** - Edges with labels connecting nodes
5. **Color coding** - Different colors for different entity types
6. **Chapter context** - Title or topic of this section

---

## Core Prompt Template

Use this template to generate prompts for nano banana:

```
Create a professional knowledge graph diagram image.

Title: {{CHAPTER_TITLE}}

Layout: {{LAYOUT_TYPE}} (hierarchical/radial/network/tree)

Entities (nodes):
{{ENTITY_LIST}}

Relationships (edges):
{{RELATIONSHIP_LIST}}

Visual Style:
- Clean, minimalist design
- White or light gray background
- Rounded rectangle nodes
- Color-coded by entity type:
  - Organization: Blue (#4A90D9)
  - Person: Green (#27AE60)
  - Technology: Purple (#9B59B6)
  - Date: Orange (#F39C12)
  - Location: Red (#E74C3C)
  - Concept: Teal (#1ABC9C)
- Labeled arrows showing relationships
- Clear, readable text labels
- Professional infographic style
```

---

## Example Prompts by Layout Type

### Hierarchical Layout

Best for: Textbooks, tutorials, organizational structures

```
Create a professional knowledge graph diagram image.

Title: "Chapter 1: AI Companies and Products"

Layout: Hierarchical (top-to-bottom tree structure)

Entities (nodes):
- OpenAI (Organization) - top level
- GPT-4 (Technology) - second level
- ChatGPT (Product) - second level
- Sam Altman (Person) - connected to OpenAI
- March 2023 (Date) - connected to GPT-4

Relationships (edges):
- OpenAI → GPT-4: "developed"
- OpenAI → ChatGPT: "released"
- Sam Altman → OpenAI: "CEO of"
- GPT-4 → March 2023: "released on"

Visual Style:
- Clean hierarchical tree flowing top to bottom
- Organization nodes in blue (#4A90D9)
- Technology nodes in purple (#9B59B6)
- Product nodes in pink (#E91E63)
- Person nodes in green (#27AE60)
- Date nodes in orange (#F39C12)
- White background
- Arrows with relationship labels
- Professional diagram style
```

### Radial Layout

Best for: Single-topic exploration, concept maps

```
Create a professional knowledge graph diagram image.

Title: "Chapter 2: Machine Learning Ecosystem"

Layout: Radial (central concept with radiating connections)

Entities (nodes):
- Machine Learning (Concept) - CENTER
- Deep Learning (Concept) - branch
- Neural Networks (Technology) - branch
- TensorFlow (Framework) - branch
- PyTorch (Framework) - branch
- Google (Organization) - outer
- Meta (Organization) - outer

Relationships (edges):
- Machine Learning → Deep Learning: "includes"
- Deep Learning → Neural Networks: "uses"
- TensorFlow → Google: "developed by"
- PyTorch → Meta: "developed by"
- Neural Networks → TensorFlow: "implemented in"
- Neural Networks → PyTorch: "implemented in"

Visual Style:
- Central node larger and prominent
- Radiating branches in all directions
- Concept nodes in teal (#1ABC9C)
- Technology nodes in purple (#9B59B6)
- Organization nodes in blue (#4A90D9)
- Light background with subtle grid
- Curved connection lines
- Modern infographic style
```

### Network Layout

Best for: Complex interconnected systems, research papers

```
Create a professional knowledge graph diagram image.

Title: "Chapter 3: Tech Industry Relationships"

Layout: Network (interconnected web of relationships)

Entities (nodes):
- Apple (Organization)
- Google (Organization)
- Microsoft (Organization)
- iPhone (Product)
- Android (Technology)
- Windows (Technology)
- Tim Cook (Person)
- Sundar Pichai (Person)

Relationships (edges):
- Apple → iPhone: "produces"
- Google → Android: "developed"
- Microsoft → Windows: "developed"
- Tim Cook → Apple: "CEO of"
- Sundar Pichai → Google: "CEO of"
- Apple ↔ Google: "competitor"
- Apple ↔ Microsoft: "competitor"
- Google ↔ Microsoft: "competitor"

Visual Style:
- Organic network layout with clusters
- Organization nodes larger, in blue (#4A90D9)
- Product nodes in pink (#E91E63)
- Technology nodes in purple (#9B59B6)
- Person nodes in green (#27AE60)
- Competitor relationships as dashed lines
- Other relationships as solid arrows
- Clean white background
- Force-directed layout appearance
```

### Tree Layout (Timeline)

Best for: Sequential processes, historical events

```
Create a professional knowledge graph diagram image.

Title: "Chapter 4: Evolution of AI"

Layout: Tree (left-to-right timeline)

Entities (nodes):
- 1950s: "AI Founded" (Event)
- 1980s: "Expert Systems" (Event)
- 2012: "Deep Learning Revolution" (Event)
- 2022: "ChatGPT Launch" (Event)
- Alan Turing (Person)
- Geoffrey Hinton (Person)
- OpenAI (Organization)

Relationships (edges):
- 1950s → 1980s: "led to"
- 1980s → 2012: "evolved into"
- 2012 → 2022: "enabled"
- Alan Turing → 1950s: "pioneered"
- Geoffrey Hinton → 2012: "led"
- OpenAI → 2022: "launched"

Visual Style:
- Horizontal timeline flowing left to right
- Event nodes as rounded rectangles on timeline
- Person/Organization nodes connected above/below
- Event nodes in dark gray (#34495E)
- Person nodes in green (#27AE60)
- Organization nodes in blue (#4A90D9)
- Timeline as a prominent horizontal line
- Clean, modern infographic style
```

---

## Prompt Generation Guidelines

### Building Prompts from JSON Triples

Given JSON triples like:
```json
[
  {"head": "Tesla", "head_type": "Organization", "relation": "founded_by", "tail": "Elon Musk", "tail_type": "Person"},
  {"head": "Tesla", "head_type": "Organization", "relation": "produces", "tail": "Model S", "tail_type": "Product"}
]
```

Generate prompt:
```
Create a professional knowledge graph diagram image.

Title: "Tesla Company Structure"

Layout: Hierarchical

Entities (nodes):
- Tesla (Organization)
- Elon Musk (Person)
- Model S (Product)

Relationships (edges):
- Elon Musk → Tesla: "founded"
- Tesla → Model S: "produces"

Visual Style:
- Organization nodes in blue (#4A90D9)
- Person nodes in green (#27AE60)
- Product nodes in pink (#E91E63)
- Clean white background
- Labeled directional arrows
- Professional diagram style
```

### Color Scheme Reference

| Entity Type | Color | Hex Code |
|-------------|-------|----------|
| Organization | Blue | #4A90D9 |
| Person | Green | #27AE60 |
| Technology | Purple | #9B59B6 |
| Date | Orange | #F39C12 |
| Location | Red | #E74C3C |
| Concept | Teal | #1ABC9C |
| Event | Dark Gray | #34495E |
| Product | Pink | #E91E63 |

### Layout Selection Guide

| Content Type | Recommended Layout |
|--------------|-------------------|
| Organizational hierarchy | Hierarchical |
| Single topic with subtopics | Radial |
| Many interconnected entities | Network |
| Timeline or process flow | Tree (horizontal) |

---

## Per-Chapter Prompt Workflow

For each chapter, generate a separate prompt and send to nano banana **sequentially**:

```
Chapter 1: Generate prompt → Send to nano banana → Wait for image → Save
Chapter 2: Generate prompt → Send to nano banana → Wait for image → Save
Chapter 3: Generate prompt → Send to nano banana → Wait for image → Save
...
```

**Do NOT send multiple prompts in parallel.** Wait for each image to complete before proceeding.

---

## Quality Tips for Better Images

1. **Limit nodes**: 10-15 entities per image for readability
2. **Clear relationships**: Use specific, concise relationship labels
3. **Consistent colors**: Stick to the color scheme for entity types
4. **Descriptive title**: Include chapter number and topic
5. **Appropriate layout**: Match layout to content structure
6. **White space**: Request clean design with adequate spacing

---

## Model-Specific Prompt Adaptations

Different image models may respond better to slightly different prompt styles:

### nano banana (Default, Recommended)

Use the standard prompt template above. nano banana excels at structured diagrams.

### DALL-E

Add more descriptive, natural language. DALL-E responds well to detailed descriptions:

```
Create a professional knowledge graph infographic diagram.

The image should show a clean, modern visualization with:
- Title at top: "Chapter 1: AI Companies"
- Nodes as rounded rectangles with company/person names
- Arrows connecting related concepts with relationship labels
- Color coding: blue for organizations, green for people, purple for technology
- White background, professional business style
- Clear, readable sans-serif text

Entities to include:
[list entities]

Connections to show:
[list relationships]

Style: Clean infographic, vector-like, professional presentation quality
```

### Midjourney

Midjourney prefers concise, artistic prompts. Add style modifiers:

```
Knowledge graph diagram, professional infographic style, showing [chapter topic].

Nodes: [entity list]
Connections: [relationship list]

Clean white background, rounded rectangle nodes, labeled arrows, color-coded by type (blue=org, green=person, purple=tech), modern minimalist design, vector illustration style --ar 16:9 --v 6
```

### Stable Diffusion

Be explicit about avoiding artistic interpretation:

```
(professional diagram:1.3), knowledge graph visualization, infographic style,

Title: "[chapter title]"
Showing connections between: [entities]
With relationships: [relationships]

(clean white background:1.2), (rounded rectangle nodes:1.1), labeled directional arrows, color-coded nodes, (no artistic interpretation:1.1), (technical diagram:1.2), corporate presentation style

Negative prompt: artistic, painterly, abstract, blurry text, decorative
```

### Ideogram

Ideogram handles text well. Be explicit about text content:

```
Create a knowledge graph diagram image with clear, readable text labels.

Title text: "[chapter title]"

Node labels (in rounded rectangles):
- "[Entity 1]" - blue box
- "[Entity 2]" - green box
- "[Entity 3]" - purple box

Arrow labels:
- Arrow from [Entity 1] to [Entity 2] labeled "[relationship]"
- Arrow from [Entity 2] to [Entity 3] labeled "[relationship]"

White background, professional infographic style, all text must be clearly legible.
```

---

## Prompt Template Selection

When generating image prompts, select template based on user-specified model:

```python
def get_prompt_template(image_model: str) -> str:
    """Return appropriate prompt template for the image model."""

    templates = {
        "nano banana": NANO_BANANA_TEMPLATE,  # Default, standard format
        "dalle": DALLE_TEMPLATE,              # More descriptive
        "midjourney": MIDJOURNEY_TEMPLATE,    # Concise with style modifiers
        "sd": STABLE_DIFFUSION_TEMPLATE,      # Explicit, with negative prompt
        "ideogram": IDEOGRAM_TEMPLATE,        # Text-focused
    }

    # Normalize model name
    model = image_model.lower().replace("-", "").replace(" ", "")

    # Map aliases
    if model in ["dalle", "dall-e", "openai"]:
        return templates["dalle"]
    elif model in ["midjourney", "mj"]:
        return templates["midjourney"]
    elif model in ["sd", "stablediffusion"]:
        return templates["sd"]
    elif model in ["ideogram"]:
        return templates["ideogram"]
    else:
        # Default to nano banana template
        return templates["nano banana"]
```
