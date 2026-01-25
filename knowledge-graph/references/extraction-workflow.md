# Extraction Workflow

Detailed procedures for chunking documents, extracting triples, generating Mermaid code, and routing image generation to nano banana.

## Model Responsibilities

| Step | Model | Output |
|------|-------|--------|
| 1. Document chunking | Default | Chapter list |
| 2. JSON triple extraction | Default | JSON files |
| 3. Mermaid.js generation | Default | .mmd files |
| 4. Image prompt generation | Default | Text prompts |
| 5. **Image generation** | **nano banana** | **PNG/JPG images** |

---

## Document Chunking Strategy

### Chunk Size Guidelines

| Document Type | Ideal Chunk Size | Boundary Strategy |
|--------------|------------------|-------------------|
| Book with chapters | 500-1000 tokens | Chapter/section headers |
| Technical article | 500-800 tokens | H2/H3 sections |
| Research paper | 600-900 tokens | Abstract, sections, conclusion |
| News article | 300-500 tokens | Paragraph boundaries |

### Chunking Algorithm

```python
def chunk_document(content: str, max_tokens: int = 800) -> list[dict]:
    """Split document into processable chunks."""
    chunks = []

    # Step 1: Identify natural boundaries
    sections = split_by_headers(content)  # H1, H2, H3

    for section in sections:
        token_count = count_tokens(section.content)

        if token_count <= max_tokens:
            chunks.append({
                "title": section.title,
                "content": section.content,
                "index": len(chunks) + 1
            })
        else:
            # Split large sections by paragraph
            sub_chunks = split_by_paragraph(section, max_tokens)
            chunks.extend(sub_chunks)

    return chunks
```

### Header Detection Patterns

```python
HEADER_PATTERNS = [
    r"^# (.+)$",           # Markdown H1
    r"^## (.+)$",          # Markdown H2
    r"^### (.+)$",         # Markdown H3
    r"^Chapter \d+[:\.]",  # Book chapters
    r"^\d+\. (.+)$",       # Numbered sections
]
```

---

## JSON Triple Extraction [DEFAULT MODEL]

### Extraction Prompt Template

```markdown
# Role
You are an expert Knowledge Graph Engineer. Extract structured knowledge from the provided text.

# Ontology Constraints
1. Allowed Entity Types: [Person, Organization, Technology, Location, Date, Concept, Event, Product]
2. Allowed Relationships: [founded_by, works_for, located_in, developed, released_on, part_of, acquired, competitor_of, caused, depends_on]

# Extraction Rules
- Extract only facts explicitly mentioned in the text
- Entities must be atomic (single concepts, not phrases)
- Resolve synonyms to their most common name
- If a relationship does not fit the allowed list, ignore it
- Maximum 15-20 triples per chunk

# Output Format
Output STRICT JSON format:
[
  {"head": "Entity A", "head_type": "Type", "relation": "relationship", "tail": "Entity B", "tail_type": "Type"}
]

# Text to Process
"""
{{CHAPTER_CONTENT}}
"""

Output JSON only:
```

### Validation

```python
def validate_triple(triple: dict, schema: dict) -> bool:
    """Validate triple against schema."""
    required_fields = ["head", "head_type", "relation", "tail", "tail_type"]

    if not all(field in triple for field in required_fields):
        return False

    if triple["head_type"] not in schema["entity_types"]:
        return False
    if triple["tail_type"] not in schema["entity_types"]:
        return False
    if triple["relation"] not in schema["relationships"]:
        return False

    return True
```

---

## Mermaid.js Generation [DEFAULT MODEL]

After extracting JSON triples, generate Mermaid code:

```python
def generate_mermaid(triples: list, chapter_title: str) -> str:
    """Generate Mermaid.js code from triples."""

    # Build node mapping
    nodes = {}
    node_id = 'A'
    for triple in triples:
        if triple["head"] not in nodes:
            nodes[triple["head"]] = {
                "id": node_id,
                "type": triple["head_type"]
            }
            node_id = chr(ord(node_id) + 1)
        if triple["tail"] not in nodes:
            nodes[triple["tail"]] = {
                "id": node_id,
                "type": triple["tail_type"]
            }
            node_id = chr(ord(node_id) + 1)

    # Generate Mermaid code
    lines = ["graph TD"]

    # Add edges
    for triple in triples:
        head_id = nodes[triple["head"]]["id"]
        tail_id = nodes[triple["tail"]]["id"]
        head_class = triple["head_type"].lower()[:3]
        tail_class = triple["tail_type"].lower()[:3]
        lines.append(f'    {head_id}[{triple["head"]}]:::{head_class} -->|{triple["relation"]}| {tail_id}[{triple["tail"]}]:::{tail_class}')

    # Add class definitions
    lines.append("")
    lines.append("    classDef org fill:#4A90D9,stroke:#2E5A8B,color:#fff")
    lines.append("    classDef per fill:#27AE60,stroke:#1E8449,color:#fff")
    lines.append("    classDef tec fill:#9B59B6,stroke:#7D3C98,color:#fff")
    lines.append("    classDef dat fill:#F39C12,stroke:#D68910,color:#fff")
    lines.append("    classDef loc fill:#E74C3C,stroke:#C0392B,color:#fff")
    lines.append("    classDef con fill:#1ABC9C,stroke:#16A085,color:#fff")

    return "\n".join(lines)
```

---

## Image Prompt Generation [DEFAULT MODEL]

Generate prompts for nano banana to create knowledge graph images:

```python
def generate_image_prompt(triples: list, chapter_title: str, layout: str) -> str:
    """Generate image prompt for nano banana model."""

    # Extract unique entities
    entities = []
    for triple in triples:
        entities.append(f"- {triple['head']} ({triple['head_type']})")
        entities.append(f"- {triple['tail']} ({triple['tail_type']})")
    entities = list(set(entities))

    # Format relationships
    relationships = []
    for triple in triples:
        relationships.append(f"- {triple['head']} → {triple['tail']}: \"{triple['relation']}\"")

    prompt = f"""Create a professional knowledge graph diagram image.

Title: "{chapter_title}"

Layout: {layout}

Entities (nodes):
{chr(10).join(entities)}

Relationships (edges):
{chr(10).join(relationships)}

Visual Style:
- Clean, minimalist design
- White background
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
"""
    return prompt
```

---

## Image Generation Workflow [SELECTED IMAGE MODEL]

Image generation supports **two processing modes** depending on agent capabilities:

### Mode Detection

```python
def detect_processing_mode(agent_capabilities, user_preference):
    """Determine whether to use parallel or sequential processing."""

    # User override takes priority
    if user_preference == "parallel":
        return "parallel"
    if user_preference == "sequential":
        return "sequential"

    # Auto-detect based on agent capabilities
    if agent_capabilities.supports_parallel_subtasks:
        return "parallel"
    else:
        return "sequential"
```

---

### Parallel Mode (Recommended when supported)

If the agent supports concurrent subtask execution, generate all images simultaneously:

```
┌─────────────────────────────────────────────────────────────┐
│  PARALLEL IMAGE GENERATION                                  │
│                                                             │
│  Spawn all tasks at once:                                   │
│  ┌─ Chapter 1 prompt → [image model] ─┐                    │
│  ├─ Chapter 2 prompt → [image model] ─┼─→ Collect results  │
│  └─ Chapter N prompt → [image model] ─┘                    │
│                                                             │
│  Time: ~1× single image generation (vs N× sequential)      │
└─────────────────────────────────────────────────────────────┘
```

**Parallel Implementation:**

```python
async def generate_all_images_parallel(chapters: list, image_model: str):
    """Generate images for all chapters in parallel."""

    print(f"Generating {len(chapters)} images in parallel using {image_model}...")

    # Spawn all image generation tasks concurrently
    tasks = []
    for chapter in chapters:
        task = spawn_image_task(
            prompt=chapter.image_prompt,
            model=image_model
        )
        tasks.append((chapter, task))

    # Wait for ALL tasks to complete
    results = await gather_all_tasks([t[1] for t in tasks])

    # Save all images
    for (chapter, _), image in zip(tasks, results):
        output_path = f"output/{chapter.folder}/knowledge-graph.png"
        save_image(image, output_path)
        print(f"  ✓ {chapter.title}: {output_path}")

    print(f"All {len(chapters)} images generated successfully!")
```

**Benefits of parallel mode:**
- ~N× faster for N chapters
- Better resource utilization
- Same quality as sequential

---

### Sequential Mode (Fallback)

If parallel not supported, process one chapter at a time:

```
┌─────────────────────────────────────────────────────────────┐
│  SEQUENTIAL IMAGE GENERATION                                │
│                                                             │
│  for chapter in chapters:                                   │
│      prompt = chapter.image_prompt                          │
│      image = send_to_image_model(prompt)   # WAIT HERE      │
│      save_image(image)                                      │
│      # Only proceed after image is saved                    │
└─────────────────────────────────────────────────────────────┘
```

**Sequential Implementation:**

```python
def generate_all_images_sequential(chapters: list, image_model: str):
    """Generate images for all chapters sequentially."""

    for i, chapter in enumerate(chapters):
        print(f"Generating image {i+1}/{len(chapters)}: {chapter.title}")

        # Send to image model and WAIT for completion
        image = route_to_image_model(chapter.image_prompt, image_model)

        # Save the image
        output_path = f"output/chapter-{i+1}/knowledge-graph.png"
        save_image(image, output_path)

        print(f"  ✓ Image saved: {output_path}")

        # Proceed to next chapter only after current is complete
```

**When to use sequential:**
- Agent doesn't support parallel subtasks
- Image API has strict rate limits
- Debugging or testing
- User explicitly requests `--sequential`

---

### Unified Entry Point

```python
async def generate_images(chapters: list, image_model: str, mode: str):
    """Generate images using detected or specified mode."""

    if mode == "parallel":
        await generate_all_images_parallel(chapters, image_model)
    else:
        generate_all_images_sequential(chapters, image_model)
```

---

## Merging Strategy

### Entity Normalization

```python
NORMALIZATION_RULES = {
    "prefixes": ["Mr.", "Mrs.", "Ms.", "Dr.", "Prof."],
    "suffixes": ["Inc.", "Corp.", "LLC", "Ltd.", "Co."],
    "aliases": {
        "Google": ["Google Inc.", "Alphabet", "Google LLC"],
        "Microsoft": ["Microsoft Corp.", "MSFT"],
    }
}

def normalize_entity(entity: str) -> str:
    """Normalize entity to canonical form."""
    normalized = entity.strip()

    for prefix in NORMALIZATION_RULES["prefixes"]:
        if normalized.startswith(prefix):
            normalized = normalized[len(prefix):].strip()

    for suffix in NORMALIZATION_RULES["suffixes"]:
        if normalized.endswith(suffix):
            normalized = normalized[:-len(suffix)].strip()

    for canonical, aliases in NORMALIZATION_RULES["aliases"].items():
        if normalized in aliases:
            return canonical

    return normalized
```

### Deduplication

```python
def deduplicate_triples(all_triples: list) -> list:
    """Remove duplicate triples."""
    seen = set()
    unique = []

    for triple in all_triples:
        key = (
            normalize_entity(triple["head"]).lower(),
            triple["relation"],
            normalize_entity(triple["tail"]).lower()
        )

        if key not in seen:
            seen.add(key)
            unique.append(triple)

    return unique
```

---

## Output Structure

```
output/
├── chapter-1/
│   ├── triples.json          # JSON 三元组 (默认模型)
│   ├── graph.mmd             # Mermaid.js 代码 (默认模型)
│   ├── image-prompt.txt      # 图像生成 prompt (默认模型)
│   └── knowledge-graph.png   # 知识图谱图片 (图像模型)
├── chapter-2/
│   ├── triples.json
│   ├── graph.mmd
│   ├── image-prompt.txt
│   └── knowledge-graph.png
├── chapter-N/
│   └── ...
├── merged-triples.json       # 所有章节合并去重
└── full-graph.mmd            # 完整 Mermaid 图
```

**文件用途：**

| 文件 | 模型 | 说明 |
|------|------|------|
| `triples.json` | 默认 | 可导入 Neo4j/NetworkX 的结构化数据 |
| `graph.mmd` | 默认 | 可在 mermaid.live 或 VS Code 预览 |
| `image-prompt.txt` | 默认 | 保存 prompt 便于调试、修改、复用 |
| `knowledge-graph.png` | 图像 | 最终可视化图片 |

---

## Progress Reporting

```markdown
## Knowledge Graph Generation Progress

| Chapter | JSON | Mermaid | Image Prompt | Image |
|---------|------|---------|--------------|-------|
| Chapter 1: Introduction | ✓ | ✓ | ✓ | ✓ |
| Chapter 2: Background | ✓ | ✓ | ✓ | ⏳ In Progress |
| Chapter 3: Methods | ✓ | ✓ | ✓ | Pending |
| Chapter 4: Results | Pending | - | - | - |

**Current**: Generating image for Chapter 2
**Model**: nano banana
```

---

## Error Handling

| Issue | Detection | Solution |
|-------|-----------|----------|
| Empty JSON response | `len(triples) == 0` | Retry with simpler prompt |
| Invalid JSON | `JSONDecodeError` | Extract JSON with regex fallback |
| Schema violation | Validation fails | Filter invalid triples |
| Image generation failed | nano banana error | Retry, then skip if persistent |
| Timeout | Task exceeds limit | Reduce chunk size |

---

## Best Practices Summary

1. **Chunk at natural boundaries** - Respect document structure
2. **Validate against schema** - Reject non-conforming triples
3. **Normalize before merge** - Canonical entity names
4. **Generate all text outputs first** - JSON, Mermaid, prompts (default model)
5. **Prefer parallel image generation** - Use parallel mode when agent supports concurrent subtasks
6. **Fallback to sequential** - Use sequential when parallel not supported or rate-limited
7. **Respect user preferences** - Honor `--parallel` or `--sequential` flags
8. **Save progress** - Store all intermediate outputs
