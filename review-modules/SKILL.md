---
name: review-modules
description: Multi-agent parallel code review for Aleph Rust modules with confidence-based scoring. Use when the user asks to "review modules", "review all modules", "code review", "review core/src", "audit codebase", "check code quality", or wants systematic module-by-module review of the Aleph project. Supports single module review, full project sweep, and resume after interruption.
---

# Multi-Agent Module Review

Systematic code review for Aleph's `core/src/` modules using parallel specialized agents and confidence-based filtering, inspired by Claude Code's official code-review plugin.

## Architecture

```
Phase 1: Discover    — auto-find all modules under core/src/
Phase 2: Triage      — haiku agent per module: skip trivial, estimate complexity
Phase 3: Review      — 4 parallel sonnet agents per module (different perspectives)
Phase 4: Score       — haiku agent per issue: confidence 0-100
Phase 5: Filter      — keep only issues >= threshold (default 80)
Phase 6: Report      — structured markdown per module + summary table
Phase 7: Fix (opt)   — sonnet agent applies fixes for high-confidence issues
```

## Workflow

### 1. Parse user intent

Determine from the user's request:
- **Scope**: single module (`teams`), or all modules
- **Resume**: continue interrupted run (`--resume`)
- **Fix mode**: also apply fixes (`--fix`)
- **Threshold**: confidence cutoff (default 80)

### 2. Discover modules

Auto-discover review targets under `core/src/`:

```bash
# Directories (module dirs, skip bin/)
find core/src/ -maxdepth 1 -mindepth 1 -type d ! -name bin ! -name '.*' | sort
# Standalone .rs files
find core/src/ -maxdepth 1 -mindepth 1 -name '*.rs' | sort
# Bin targets
find core/src/bin/ -maxdepth 1 -mindepth 1 -type d | sort
```

Or use the helper script: `bash scripts/review-all-modules.sh --discover`

### 3. Triage (skip if single module)

For full sweep, launch a **haiku** agent per module to count files and estimate complexity. Skip modules with 0 .rs files or <50 total lines.

### 4. Multi-agent parallel review

For each module, launch **4 parallel agents** (sonnet, via Agent tool):

| Agent | Focus | Checklist |
|-------|-------|-----------|
| Security | UTF-8 safety, lock poisoning, unwrap, SQL injection, static mut, races | See [checklist.md](references/checklist.md) §1 |
| Logic | State machines, error propagation, boundaries, off-by-one, match arms | See [checklist.md](references/checklist.md) §2 |
| Architecture | CLAUDE.md redlines R1-R10, design principles P1-P8 | See [checklist.md](references/checklist.md) §3 |
| Quality | Dead code, DRY, function length, HashMap order, pub scope | See [checklist.md](references/checklist.md) §4 |

Each agent MUST read the module's .rs files and return issues in this exact format:

```
ISSUE|<file>:<line>|<severity:low/medium/high/critical>|<description>|<evidence>
```

Or `NO_ISSUES` if clean.

### 5. Confidence scoring

For each collected issue, launch a **haiku** agent that:
1. Reads the issue and referenced code
2. Scores confidence 0-100:
   - **0**: False positive
   - **25**: Might be real, likely false positive
   - **50**: Real but minor/rare
   - **75**: Verified real, impacts functionality
   - **100**: Confirmed, frequent in practice
3. Returns: `SCORE|<number>|<reason>`

**False positive patterns** (score 0-25):
- Pre-existing issues not recently introduced
- Issues clippy/compiler would catch
- Pedantic nitpicks
- Style issues not in CLAUDE.md
- Intentional design choices

### 6. Filter and report

Filter issues below threshold. Write per-module report to `review-results/<module>.md`:

```markdown
# Module: <name>

## Summary
- Path: core/src/<name>/
- Issues found: N
- After filtering (threshold=80): M

## High-Confidence Issues
### 1. [agent] Description (confidence: 95)
- **File**: `file.rs:42`
- **Severity**: high
- **Evidence**: ...
```

Append to `review-results/_summary.md`:

```markdown
| Module | Raw Issues | After Filter | Status |
```

### 7. Fix mode (only if user requested `--fix`)

Launch a **sonnet** agent per module that:
1. Reads only the filtered issues
2. Fixes each in source code
3. Runs `cargo check -p alephcore`
4. Reports what was fixed

## Key Rules

- **Review only by default** — never auto-fix unless `--fix` specified
- **4 parallel agents per module** — always launch simultaneously via Agent tool
- **Score every issue** — no issue bypasses confidence scoring
- **Structured output** — agents MUST use `ISSUE|...|...|...|...` format
- **Resume support** — skip modules with existing report in `review-results/`
- **Cargo check after fix** — every fix must compile
- **Sequential modules** — review one module at a time to avoid context overflow

## Shell Script Alternative

The same workflow is also available as `scripts/review-all-modules.sh` for headless/CI use:

```bash
./scripts/review-all-modules.sh                     # Review all modules
./scripts/review-all-modules.sh --resume            # Resume interrupted run
./scripts/review-all-modules.sh --module teams      # Single module
./scripts/review-all-modules.sh --fix               # Review + fix
./scripts/review-all-modules.sh --threshold 60      # Lower threshold
./scripts/review-all-modules.sh --parallel 3        # N modules in parallel
./scripts/review-all-modules.sh --discover          # Show discovered modules
```
