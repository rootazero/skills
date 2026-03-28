# Aleph Code Review Checklist

## 1. Security & Robustness

### UTF-8 Safety
- `&s[..n]` byte slicing panics on multi-byte chars
- Fix: use `s.get(..n)`, `char_indices()`, or `strip_suffix()`

### Lock Poisoning
- `lock().unwrap()` cascades panics across threads
- Fix: `.unwrap_or_else(|e| e.into_inner())`

### Unwrap on User Paths
- `unwrap()`/`expect()` on: `home_dir()`, timestamps, HTTP clients, file I/O
- Fix: use `?` operator or provide fallback

### SQL Injection
- `format!()` building LanceDB DataFusion filter strings
- Fix: use `escape_sql_string()` helper

### Static Mut
- `static mut` is unsound in Rust
- Fix: use `OnceLock`, `LazyLock`, or `Lazy`

### Race Conditions
- Lock ordering violations (check lock hierarchy in `sync_primitives.rs`)
- Level 0: StateDatabase → 1: MemoryStore → 2: ToolRegistry → 3: UI

## 2. Logic & Correctness

### State Machines
- Missing transition arms in state machine `match` blocks
- Unreachable states that should be reachable

### Error Propagation
- `unwrap()` swallowing error context mid-chain
- `.ok()` silently discarding errors that callers need
- `map_err` losing original error info

### Boundary Conditions
- Empty collections: `.first().unwrap()`, `[0]` on empty vec
- Zero/negative values in division, indexing
- Integer overflow in arithmetic (especially `usize` subtraction)

### Off-by-One
- Loop bounds: `..len()` vs `..=len()`
- Slice ranges
- Pagination offsets

### Pattern Matching
- Non-exhaustive `match` without meaningful `_ =>` fallback
- Missing enum variants after additions

## 3. Architecture Compliance

### Redlines (from CLAUDE.md)
- **R1**: No platform APIs (AppKit, Vision, CoreGraphics, windows-rs) in `core/src/`
- **R3**: No heavy third-party libs for non-core single-use features
- **R4**: No business logic in interface layer (pure I/O only)
- **R8**: No deterministic code replacing LLM reasoning (intent detection rules, POE pipelines, tool filters)
- **R9**: Configurable operations should be exposed as tools
- **R10**: Intelligence lives in prompts, not middleware

### Design Principles
- **P1 Low Coupling**: Modules via traits, no cross-layer direct calls, dependency flows `Interface → Core → Domain`
- **P2 High Cohesion**: Single responsibility, related logic grouped, files <500 lines
- **P4 Dependency Inversion**: Core defines traits, implementations outside or injectable
- **P5 Least Knowledge**: No `a.b().c().d()` chains, minimal pub API
- **P6 Simplicity**: No premature abstractions, dead code deleted, flat > nested

## 4. Code Quality

### Dead Code
- Unused functions, imports, types, enum variants
- Commented-out code blocks (delete, git is the time machine)

### DRY Violations
- Duplicated logic across 3+ locations
- Copy-pasted error handling patterns
- Repeated struct construction

### Function Length
- Functions >50 lines: identify split points
- Deeply nested code (>4 levels): use early return / `?`

### HashMap Ordering
- Security-sensitive iteration over `HashMap` (rules, permissions)
- Fix: sort explicitly or use `BTreeMap`

### Visibility
- `pub` where `pub(crate)` suffices (only crate-internal access)
- Exposed internal fields that should have accessor methods
