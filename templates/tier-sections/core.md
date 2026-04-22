# Section: Core

**Trigger tag:** `always` — every phase that ships code gets Core rendered in full. Core dimensions are never suppressed by Layer 2 LLM filter.

**Purpose:** Baseline engineering posture. Applies to any code-shipping phase regardless of domain.

## Dimensions (4)

| Dimension            | MVP                  | Δ(M→E) | Enterprise           | Δ(E→S) | Scale               |
|----------------------|----------------------|--------|----------------------|--------|---------------------|
| Testing              | happy path           | L      | + edges              | M      | + fuzz + load eval  |
| Error handling       | fail loud            | L      | typed + retry        | S      | + circuit break     |
| Observability        | print/log            | M      | structured log       | L      | + metrics + traces  |
| Abstractions         | inline               | S      | 1 interface          | S      | strategy + DI       |

## Notes

- **Testing:** "happy path" = assert the happy case and nothing else. Edge coverage and load eval are tier upgrades, not negotiable features.
- **Error handling:** "fail loud" = let exceptions propagate. No swallowing. Retry + circuit break gate progressive tiers.
- **Observability:** Upgrade path tracks debuggability under real traffic, not nice-to-have metrics.
- **Abstractions:** Core rule — MVP inlines, Enterprise allows one interface per extension point, Scale permits strategy pattern + DI container only when registered-implementation count ≥ 3.

## Core never filtered

Unlike domain sections (Data, AI/Agent, etc.) where LLM may suppress irrelevant rows, Core always renders all 4 dimensions. Rationale: every phase has testing / error / obs / abstraction decisions even if implicit. Forcing the 4-row render surfaces the implicit defaults.

## Tier-cap enforcement (read by /gabe-execute)

- **MVP phase:** tasks that introduce abstractions beyond "1 interface" halt exec with escalation gate. `Strategy` / `DI container` / `multi-backend plugin` trigger drift.
- **Enterprise phase:** tasks that add circuit breakers / SLO alerting halt unless task description references Scale responsibility.
- **Scale phase:** no inline enforcement — any pattern allowed.

## Known drift signals (read by /gabe-review)

| Pattern                                   | Tier floor | Finding severity |
|-------------------------------------------|------------|------------------|
| `@retry` / `tenacity` / `@circuit_breaker`| Enterprise | TIER_DRIFT-HIGH  |
| DI container (`dependency-injector`, `kink`)| Scale    | TIER_DRIFT-HIGH  |
| Strategy pattern + plugin registry        | Scale      | TIER_DRIFT-HIGH  |
| Fuzz test / hypothesis strategies         | Scale      | TIER_DRIFT-MED   |
| Structured logger w/ trace correlation    | Enterprise | TIER_DRIFT-MED   |
| Metrics exporter (prometheus, otel)       | Enterprise | TIER_DRIFT-MED   |
