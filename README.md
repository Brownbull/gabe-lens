# gabe-lens

Cognitive translation plugin for Claude Code. Transforms complex technical concepts into physical-system analogies, ASCII spatial maps, constraint boxes, and memorable one-line handles.

Built for **visual-spatial, conceptual-analogical, top-down constraint-driven** thinkers who learn best through the sequence: **Problem → Analogy → Code**.

## What It Does

When you encounter a complex concept, `/gabe-lens` produces a **Gabe Block** — a structured explanation format:

```
┌─── GABE BLOCK: [Concept] ────────────────────────────┐
│                                                        │
│  THE PROBLEM   — Why this exists (purpose-first)       │
│  THE ANALOGY   — Physical system you can visualize     │
│  ANALOGY LIMITS — Where the analogy breaks             │
│  THE MAP       — ASCII spatial diagram                 │
│  CONSTRAINT BOX                                        │
│    IS:      what it is                                 │
│    IS NOT:  what it isn't (prevents overthinking)      │
│    DECIDES: what trade-off it resolves                 │
│  ONE-LINE HANDLE — memorable phrase that survives       │
│                    fatigue and context loss             │
│  SIGNAL — Quick check ✓ or Deeper question ◆           │
│                                                        │
└────────────────────────────────────────────────────────┘
```

## Installation

### From GitHub (recommended)

```bash
claude plugin add Brownbull/gabe_lens
```

### Manual installation

Add to your `~/.claude/settings.json`:

```json
{
  "enabledPlugins": {
    "gabe-lens@Brownbull/gabe_lens": true
  }
}
```

## Usage

### Explain a concept (full block — default)

```
/gabe-lens [concept or question]
```

Transforms a single concept into a full Gabe Block with all components.

**Example:** `/gabe-lens dependency injection`

### Brief (`brief` | `bf`)

```
/gabe-lens brief [concept]
/gabe-lens bf [concept]
```

Produces one-line handle + constraint box only (~40-80 tokens). Use when the concept has been introduced before or space is tight.

**Example:** `/gabe-lens bf dependency injection`

### Oneliner (`oneliner` | `ol`)

```
/gabe-lens oneliner [concept]
/gabe-lens ol [concept]
```

Produces only the one-line handle (~5-15 tokens). Use for compaction handoffs, session re-anchoring, or when every token counts.

**Example:** `/gabe-lens ol dependency injection`

### Annotate (`annotate` | `an`)

```
/gabe-lens annotate [file-path]
/gabe-lens an [file-path]
```

Reads a document and produces a companion file with Gabe Blocks for the 3-5 most critical concepts.

**Example:** `/gabe-lens an docs/architecture.md` → creates `docs/architecture-gabe-lens.md`

### Session map

```
/gabe-lens map
```

Produces a spatial session map showing DONE / NOW / NEXT with one-line handles.

## Analogy Domains

The skill draws analogies from physical systems you can visualize in 3D space (in preference order):

1. Mechanical systems (gears, valves, pulleys)
2. Fluid dynamics (pressure, flow, reservoirs)
3. Optics/light (lenses, mirrors, refraction)
4. Chemistry (reactions, catalysts, equilibrium)
5. Electromagnetism (fields, circuits, charges)
6. Thermodynamics (heat, entropy, engines)
7. Biology (cells, ecosystems, evolution)

If no good physical analogy exists, the skill says so explicitly rather than forcing a weak metaphor.

## Compression Modes

| Context | Mode | Command | Tokens |
|---|---|---|---|
| First time explaining a concept | Full | `/gabe-lens` | ~200-350 |
| Referencing a previously explained concept | Brief | `/gabe-lens bf` | ~40-80 |
| Compaction handoff or session re-anchoring | Oneliner | `/gabe-lens ol` | ~5-15 |
| Writing documentation for humans | Full | `/gabe-lens` | ~200-350 |

## Embedding in Workflows

Add to any workflow's knowledge loading:

```yaml
project_knowledge:
  optional:
    - "skills/gabe-lens/SKILL.md"
```

The skill also enhances compaction handoff notes by including one-line handles that survive context compression.

## License

MIT
