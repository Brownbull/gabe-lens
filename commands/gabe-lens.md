---
name: gabe-lens
description: Transform technical concepts into your cognitive format — physical analogies, spatial maps, constraint boxes.
---

# Gabe Lens

Cognitive translation tool. Transforms complex technical content into a visual-spatial, analogical reasoning format.

## Before Anything Else

Read the full skill definition from the gabe-lens skill (`SKILL.md`). This contains:
- The cognitive profile (visual-spatial, conceptual-analogical, top-down constraint-driven)
- The Gabe Block template and rules for each component
- When to apply / when not to apply
- Examples of well-formed Gabe Blocks

## Modes

### Mode 1: Explain (default)

**Usage:** `/gabe-lens [concept or question]`

Transform a single concept into a Gabe Block. Steps:

1. Read the gabe-lens SKILL.md for format rules
2. Identify the core concept from the user's input
3. Produce a single, well-formed Gabe Block with all components:
   - THE PROBLEM (purpose-first)
   - THE ANALOGY (physical system)
   - THE MAP (ASCII spatial diagram)
   - CONSTRAINT BOX (IS / IS NOT / DECIDES)
   - ONE-LINE HANDLE (5-10 words, survives fatigue)
   - SIGNAL (Quick check or Deeper question)

### Mode 2: Annotate

**Usage:** `/gabe-lens annotate [file-path]`

Read a document and produce a companion file with Gabe Blocks for its key concepts. Steps:

1. Read the gabe-lens SKILL.md for format rules
2. Read the target document fully
3. Identify the 3-5 most complex or critical concepts (not trivial facts)
4. For each concept, produce a complete Gabe Block
5. Write the companion file to the same directory as the original, named `{original-name}-gabe-lens.md`
   - Example: `docs/04-gate-audit.md` → `docs/04-gabe-lens.md`
6. The companion file should:
   - Reference the source document at the top
   - Present Gabe Blocks in the order they appear in the source
   - Include a brief intro explaining what this file is

### Mode 3: Session Map

**Usage:** `/gabe-lens map`

Produce a spatial session map of the current work state:

```
SESSION MAP — [timestamp]
┌── DONE ─────────────────────────────────┐
│ [completed items with one-line handles]  │
└──────────────────────────────────────────┘
        │
        ▼
┌── NOW ──────────────────────────────────┐
│ [current task]                           │
│ [decision point if any]                  │
└──────────────────────────────────────────┘
        │
        ▼
┌── NEXT ─────────────────────────────────┐
│ [upcoming items — do NOT start yet]      │
└──────────────────────────────────────────┘
```
