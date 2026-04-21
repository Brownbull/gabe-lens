# Gabe Lens Prompts

Versioned LLM (Large Language Model) prompts used by the Gabe Lens command suite. These are build-time assets during development; final shipping form decided in Phase 7 of the `/gabe-scope` implementation plan (ship to `~/.claude/prompts/` vs. inline into command files).

## File naming convention

```
{prompt-id}.md
```

Where `{prompt-id}` is lowercase-kebab-case matching the prompt's purpose. Examples:

- `intake-quality-evaluator.md`
- `brainstorm-analyst.md`
- `scope-change-classifier.md`

## Frontmatter schema

Every prompt file MUST begin with YAML frontmatter:

```yaml
---
id: intake-quality-evaluator
version: v1                  # v{N}; bump on any semantic change
model: opus                  # opus | sonnet | haiku
token_budget: 800            # max tokens the prompt (including context injection) should consume per call
output_format: json          # json | markdown | plain
rubric: rubrics/intake-quality-evaluator.json
fixtures:
  - fixtures/spec-quality-user/
  - fixtures/idea-quality-user/
  - fixtures/mixed-user/
description: >
  Evaluates a user's interview answer and returns a structured verdict:
  spec-quality (accept) or idea-quality (trigger brainstorm sub-loop).
---
```

### Field meanings

| Field | Required | Purpose |
|---|---|---|
| `id` | yes | Stable identifier; must match filename without `.md` |
| `version` | yes | `v{N}` integer versioning; bump on any semantic change |
| `model` | yes | Tier per design §5 |
| `token_budget` | yes | Cap measured in **tokens** (≈ 4 chars per token). Harness rubrics assert in **characters** via `max_chars` — multiply `token_budget × 4` for the rough char equivalent |
| `output_format` | yes | Used by harness to select parser |
| `rubric` | yes | Path (relative to `gabe_lens/tests/scope-prompt-harness/`) to scoring rubric |
| `fixtures` | yes | Paths to ≥3 fixture directories |
| `description` | yes | One-paragraph purpose for human readers |

## Prompt body structure

After frontmatter, prompt content follows this convention:

```markdown
## System role
One paragraph establishing the persona and constraints.

## Inputs
Enumerate fields the prompt expects (injected at runtime by the command).
Use `{{placeholder}}` syntax for variables.

## Reasoning
What the model should think about. Stepwise if complex.

## Output contract
Exact output shape. For JSON outputs, include a schema. For markdown,
show the section structure. Deviations from this shape fail the rubric.

## Examples
One or two worked examples showing input → output.
```

## Version bump policy

Bump `version:` when:

- Output schema changes (new fields, renamed fields, changed types)
- System role / persona changes materially
- Reasoning steps added or reordered
- Token budget changes

Do NOT bump for:

- Typo fixes
- Example clarifications that don't change semantics
- Documentation-only edits

When `version:` bumps, any in-progress session that recorded the old version in `scope-session.json` MUST force a fresh start with a warning to the user (per design §8 risk last row).

## Token vs. character accounting

Prompt frontmatter declares `token_budget` in **tokens** (the LLM's native unit). Rubrics in `tests/scope-prompt-harness/rubrics/` assert in **characters** via the `max_chars` assertion type, since bash/jq can count characters trivially but not tokens.

**Conversion rule of thumb:** 1 token ≈ 4 characters for English prose and structured JSON. A prompt with `token_budget: 600` corresponds to roughly `max_chars: 2400` in its rubric.

Individual prompts may deviate from 4:1:
- JSON-dense outputs compress slightly better (~3.5:1)
- Prose-heavy outputs (brainstorm framings, reference summaries) run closer to 4.2:1
- Always round the `max_chars` value **up** to avoid truncating valid outputs

When `token_budget` changes, update `max_chars` in the corresponding rubric file. The harness will flag budget overruns via `max_chars` failures.

## Testing

Every prompt must pass its rubric against all declared fixtures before landing on main. See `tests/scope-prompt-harness/README.md`.

## Phase 1 status

Only `_placeholder.md` exists (a dummy prompt used to verify the harness works). Real prompts arrive in Phase 3 of the implementation plan.
