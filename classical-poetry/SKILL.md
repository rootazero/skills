---
name: classical-poetry
description: Create and validate classical Chinese poetry (律诗/绝句/排律、词、曲、对联) with meter/rhyme checks, including pingshui/new/tong韵, 词谱格式、曲牌格律、对仗平仄与词汇建议。Use when generating or correcting poems/cis/qu/couplets to match a specified theme, form, or meter, or when analyzing平仄、押韵、对仗、用韵与替换建议. Trigger when user asks to write/create/generate classical Chinese poetry, couplets, ci (词), or qu (曲), or when they ask to check/validate/analyze meter, rhyme, or tonal patterns.
---

# Classical Poetry Creation Workflow

This skill guides you through creating classical Chinese poetry (诗/词/曲/对联) with proper meter and rhyme validation. Use a structured workflow: Requirements Gathering → Context & Inspiration → Drafting → Validation → Refinement.

## When to Offer This Workflow

**Trigger conditions:**
- User asks to write classical poetry: "写一首诗", "create a poem", "作诗"
- User mentions specific forms: "五言绝句", "七律", "词", "对联"
- User asks to validate existing poetry: "check this poem", "这首诗格律对吗"
- User provides a theme and wants a poem: "写一首关于中秋的诗"

**Initial offer:**
Offer the structured workflow for poetry creation. Explain the stages:

1. **Requirements Gathering**: Determine genre, form, rhyme system, theme
2. **Context & Inspiration**: Build imagery pool from classical references
3. **Drafting**: Create the poem using appropriate imagery and structure
4. **Validation**: Check meter, rhyme, and tonal patterns automatically
5. **Refinement**: Fix any issues and polish the poem

Explain that this ensures the poem follows proper classical Chinese poetry rules (格律). Ask if they want to use this workflow or prefer freeform composition.

If user declines, compose freeform. If user accepts, proceed to Stage 1.

## Stage 1: Requirements Gathering

**Goal:** Understand exactly what type of poetry to create and the constraints.

### Initial Questions

Ask the user for specific requirements:

1. **Genre** (体裁): 诗 (shi poetry), 词 (ci lyric), 曲 (qu opera lyric), or 对联 (couplet)?
2. **Form** (格式):
   - For 诗: 五言绝句, 七言绝句, 五言律诗, 七言律诗, 排律?
   - For 词: Which 词牌 (ci pattern)? E.g., 水调歌头, 念奴娇, 定风波
   - For 曲: Which 曲牌 (qu pattern)? E.g., 天净沙
   - For 对联: How many characters?
3. **Rhyme system** (韵书): 平水韵 (traditional), 中华新韵 (modern), or 中华通韵?
4. **Language**: 简体字 (simplified) or 繁体字 (traditional)?
5. **Theme** (主题): What is the poem about?
6. **Mood/Style** (意境): Any specific emotional tone or imagery preference?

Inform them they can answer in any format. If they've already specified some requirements, only ask about missing information.

**Common defaults if user doesn't specify:**
- Rhyme system: 平水韵 (most classical)
- Language: 简体字
- Form: 七言绝句 (most popular for beginners)

**Exit condition:**
Have clear answers for: genre, form, theme. Rhyme system and language can use defaults.

**Transition:**
Confirm the requirements with the user. For example:
"I'll create a 七言绝句 about 中秋 using 平水韵 in simplified Chinese. Ready to gather inspiration?"

Proceed to Stage 2.

## Stage 2: Context & Inspiration

**Goal:** Build an imagery pool from classical poetry on the same theme to ensure authentic classical style.

### Reference Search

Use `scripts/reference_builder.py` to fetch related classical poems:

```bash
~/.uv/python3/bin/python scripts/reference_builder.py \
  --keyword "[THEME]" --pages 3 --scope Sentence --top 40 \
  --out "/tmp/poetry_refs.json"
```

**Important:** Extract only imagery tokens (意象) and high-frequency words, NOT complete lines. This prevents plagiarism while providing classical vocabulary.

### Imagery Analysis

From the reference search results:
1. Identify common imagery patterns (e.g., for 中秋: 月, 思乡, 桂花, 玉兔)
2. Note tonal characteristics of frequently used words
3. Consider seasonal and emotional associations

**If reference search unavailable:**
Draw from general knowledge of classical Chinese poetry conventions for the theme.

**Exit condition:**
Have a pool of 15-30 relevant classical imagery terms and phrases.

**Transition:**
Announce: "I've gathered classical imagery for [THEME]. Ready to draft the poem."

Proceed to Stage 3.

## Stage 3: Drafting

**Goal:** Compose the poem using proper structure and classical imagery.

### Drafting Guidelines

**For 诗 (Shi Poetry):**
- Keep the meter pattern in mind (五言: 5 chars/line, 七言: 7 chars/line)
- Plan rhyme positions (绝句: lines 2&4, 律诗: lines 2,4,6,8)
- Use imagery from the pool naturally
- Follow 起承转合 structure for quatrains

**For 词 (Ci):**
- Must match the exact 词牌 pattern (character count per line)
- Rhyme positions depend on the specific 词牌
- May require specific tonal patterns for certain positions

**For 曲 (Qu):**
- Follow the 曲牌 pattern if specified
- More flexible than 词, allows 衬字 (padding words)

**For 对联 (Couplets):**
- Upper and lower lines must have matching tones (平仄相对)
- Semantic parallelism required
- Upper line ends with 仄, lower line ends with 平

### Composition Process

1. Draft the complete poem based on requirements and imagery pool
2. Present the draft to the user
3. Immediately proceed to validation (Stage 4) without waiting

**Do NOT ask if the draft is okay** - validation will reveal issues objectively.

## Stage 4: Validation

**Goal:** Use automated tools to check meter, rhyme, and tonal patterns.

### Running Validation

Based on the genre, run the appropriate checker:

**For 诗 (Shi):**
```bash
~/.uv/python3/bin/python scripts/poetry_checker.py \
  --mode shi --text "[POEM_TEXT]" --yun-shu [1|2|3] [--trad]
```

**For 词 (Ci):**
```bash
~/.uv/python3/bin/python scripts/poetry_checker.py \
  --mode ci --text "[POEM_TEXT]" --ci-pai "[CI_PAI_NAME]" \
  --ci-pu [1|2] --yun-shu [1|2|3] [--trad]
```

**For 曲 (Qu):**
```bash
~/.uv/python3/bin/python scripts/poetry_checker.py \
  --mode qu --text "[POEM_TEXT]" --qu-pai "[QU_PAI_NAME]" \
  --yun-shu [1|2|3] [--trad]
```

**For 对联 (Couplet):**
```bash
~/.uv/python3/bin/python scripts/poetry_checker.py \
  --mode couplet --upper "[UPPER_LINE]" --lower "[LOWER_LINE]" \
  --yun-shu [1|2|3] [--auto-suggest]
```

### Interpreting Results

The checker outputs:
- **〇** = Correct tonal position
- **●** = Incorrect tonal position (needs fixing)
- **◎** = Polyphone character (多音字, needs context verification)
- **�** = Unrecognized character

**Exit condition:**
- If validation passes (all 〇 marks): Proceed to Stage 5 for final review
- If validation fails (any ● or ◎ marks): Enter refinement loop

## Stage 5: Refinement

**Goal:** Fix tonal issues and polish the poem while preserving meaning and imagery.

### Fixing Tonal Issues

For each ● or ◎ position:

1. **Identify the problem**: Which character violates the tonal pattern?
2. **Find alternatives**: Use `scripts/souyun_api.py` to find words with correct tones
3. **Consider meaning**: Choose alternatives that preserve or enhance meaning
4. **Check for 多音字**: Verify polyphone characters are pronounced correctly in context

### For Couplets

Use the `--auto-suggest` flag to automatically generate alternative characters:

```bash
~/.uv/python3/bin/python scripts/poetry_checker.py \
  --mode couplet --upper "[UPPER]" --lower "[LOWER]" \
  --yun-shu 1 --auto-suggest
```

The tool will suggest replacements for mismatched positions.

### Refinement Process

1. Make targeted character substitutions
2. Re-run validation
3. If new issues appear, repeat
4. Once validation passes, present the corrected version to user

**Important:**
- Change only what's necessary to fix tonal issues
- Preserve the core imagery and meaning
- Maintain natural flow and readability

### Allow User Edits

After presenting the refined version:
- Ask if the user wants any meaning or imagery changes
- If yes, make changes and re-validate
- Iterate until user is satisfied

**Exit condition:**
Validation passes AND user approves the content.

## Stage 6: Final Delivery

**Goal:** Present the completed poem with validation report.

### Presentation Format

Present the final poem with:
1. The complete poem text
2. Brief validation summary (e.g., "五言绝句, 平水韵尤韵, 格律正确")
3. Tonal pattern display (optional, only if user wants to see details)
4. Any notes about imagery choices or historical allusions used

### Optional Elements

Offer to provide:
- Explanation of imagery and allusions
- Pinyin or pronunciation guide
- Translation to modern Chinese or English
- Calligraphy-style formatting

**Completion:**
Confirm the poem is complete. Ask if they want to create another poem or make any final adjustments.

## Technical Reference

For detailed documentation on scripts and APIs, see:
- `references/souyun_api.md` - API endpoints for rhyme lookup and word suggestions
- `references/qu_patterns.md` - 曲牌 pattern templates
- The scripts in `scripts/` directory handle validation automatically

### Key Scripts

- `scripts/poetry_checker.py` - Main validation tool for all genres
- `scripts/reference_builder.py` - Fetch classical poetry references by theme
- `scripts/souyun_api.py` - Helper functions for online rhyme dictionary
- `scripts/review_pipeline.py` - Automated validation and review workflow

### Configuration

- **Rhyme systems**: 1=平水韵, 2=中华新韵, 3=中华通韵
- **词谱**: 1=钦定词谱, 2=龙榆生词谱
- **Python runtime**: `~/.uv/python3/bin/python`

## Tips for Effective Poetry Creation

**Workflow Tips:**
- Don't rush - classical poetry requires multiple validation iterations
- Trust the automated checker over intuition for tonal patterns
- Use the reference search to ensure classical authenticity

**Common Issues:**
- 多音字 (polyphones): Verify pronunciation in context
- 孤平 violations: Often fixed by changing one character
- Rhyme mismatch: Use Souyun API to find rhyming alternatives

**Quality Indicators:**
- Natural flow despite tonal constraints
- Vivid imagery appropriate to theme
- Emotional resonance and 意境
- No forced or awkward phrasing just to meet meter

**For Advanced Users:**
- 对仗 (parallelism) in 律诗 is checked but can be refined manually
- Consider historical allusions for depth
- 词 and 曲 often have more flexible tonal patterns than 诗
