# Section: AI/Agent

**Trigger tags:** `ai-agent`, `llm`

**Purpose:** LLM orchestration, eval, structured output, fallback. Applies to phases that integrate with an LLM or run an agent loop.

## Dimensions (4)

| Dimension            | MVP                  | Δ(M→E) | Enterprise           | Δ(E→S) | Scale               |
|----------------------|----------------------|--------|----------------------|--------|---------------------|
| Prompt eval          | eyeball 3 cases      | L      | eval set + regress   | M      | + auto eval CI      |
| Cost/latency budget  | none                 | M      | per-call logged      | M      | + SLO + alert       |
| Structured output    | regex parse          | XL     | tool/output_type     | M      | + fallback chain    |
| Fallback chain       | crash on fail        | L      | 1 retry + null       | M      | + multi-model chain |

## Notes

- **Prompt eval:** MVP = manual inspection of 3 example inputs. Enterprise = persisted eval set with regression tests. Scale = CI-gated automated evals on every prompt change.
- **Cost/latency budget:** MVP = no visibility, pray. Enterprise = per-call tokens + $ logged to structured log. Scale = SLO + alerting on cost/latency anomalies. Ties to U8 value (Measure the Machine).
- **Structured output:** XL skip MVP→Ent. Ties to U4 value (Enforce Output Structure Mechanically). MVP regex parse is the documented anti-pattern. Enterprise = PydanticAI `output_type` or Claude `tool_choice`. Scale adds deterministic fallback chain (regex → rule-based → safe default).
- **Fallback chain:** MVP = crash and surface error. Enterprise = single retry then null/default. Scale = multi-model cascade (cheap → expensive), each with its own structured-output enforcement.

## Tier-cap enforcement

- **MVP phase:** LLM caller using `tool_choice` or `output_type` = already Enterprise tier. Escalation prompt.
- **MVP phase:** eval set files (`evals/*.json`, `pytest` parameterized over LLM cases) trigger escalation.
- **Enterprise phase:** multi-model cascade scaffolding triggers Scale escalation.

## Known drift signals

| Pattern                                           | Tier floor | Finding severity  |
|---------------------------------------------------|------------|-------------------|
| PydanticAI `Agent(output_type=...)`               | Enterprise | TIER_DRIFT-MED    |
| `tool_choice` / `response_format: json_schema`    | Enterprise | TIER_DRIFT-MED    |
| Structured fallback chain (regex → rule → default)| Scale      | TIER_DRIFT-HIGH   |
| Token/cost logging middleware                     | Enterprise | TIER_DRIFT-LOW    |
| Eval harness (langchain evaluators, custom runners)| Enterprise| TIER_DRIFT-MED    |
| CI-gated prompt regression suite                  | Scale      | TIER_DRIFT-MED    |
| Multi-model router (cheap-first cascade)          | Scale      | TIER_DRIFT-HIGH   |

## Red-line items

- **U4 structured output.** MVP phases that touch LLM output for downstream code to consume MUST use framework-level enforcement, not regex parse. If a phase declares MVP tier but the downstream consumer is code (not human), `/gabe-plan` should BLOCK with: "Structured output is load-bearing — skip MVP on this row (force Enterprise minimum)."
- **U8 cost visibility.** Any agent-application phase that promises cost control in scope MUST have per-call logging at minimum. `none` on cost/latency is acceptable only for throwaway prototypes.
