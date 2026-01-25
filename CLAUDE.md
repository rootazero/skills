# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Purpose

This is a **Skills development project** for creating reusable Claude Code skills. Skills are modular packages that extend Claude's capabilities with specialized workflows, prompts, and reference materials.

## Skill Structure

Each skill follows this standard structure:

```
skill-name/
├── SKILL.md              # Required: Main skill documentation with YAML frontmatter
└── references/           # Optional: Supporting documentation and templates
    ├── prompts/          # Prompt templates
    ├── styles/           # Style definitions (for visual skills)
    └── layouts/          # Layout templates (for graph/diagram skills)
```

### SKILL.md Format

Every SKILL.md must have:
1. **YAML frontmatter** with `name` and `description` fields
2. **Markdown body** with workflow instructions, examples, and usage patterns

```yaml
---
name: skill-name
description: When to use this skill and what it does
---
```

## Current Skills

| Skill | Purpose |
|-------|---------|
| `cover-image/` | Generate article cover images with 8 style presets |
| `knowledge-graph/` | Generate knowledge graphs from documents (JSON triples, Mermaid, images) |

## Skill Development Workflow

1. Create skill folder with `SKILL.md`
2. Add reference files in `references/` subdirectory
3. Use skill-creator's validation: `~/.uv/python3/bin/python ~/.claude/skills/skill-creator/scripts/package_skill.py <skill-folder>`
4. Package outputs a `.skill` file (ZIP archive)

## Key Design Patterns

### Dual-Model Architecture
Skills often separate text generation (default model) from image generation (user-specified model like nano banana, DALL-E, Midjourney).

### Processing Modes
For batch operations, support both:
- **Parallel**: Concurrent subtasks when agent supports it
- **Sequential**: Fallback for rate-limited APIs or unsupported agents

### Schema-Constrained Extraction
For knowledge extraction tasks, predefine allowed entity types and relationship types to prevent hallucination.

## Environment

- Python path: `~/.uv/python3/bin/python`
- Install Python package: `cd ~/.uv/python3 && uv pip install <package>`

## Conventions

- Skill names use `hyphen-case`
- Reference files are markdown (`.md`)
- Image prompts should specify model-specific adaptations
- Support both Chinese and English in user-facing content
- Output files organized in predictable directory structures
