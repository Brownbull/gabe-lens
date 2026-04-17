---
id: model-routing-by-task
name: Model Routing by Task Complexity
tier: foundational
specialization: [cost, agent]
tags: [routing, model-selection, haiku, sonnet, opus]
prerequisites: []
related: [pattern-multi-model-pipeline, token-budget-caps]
one_liner: "Cheap model for sorting, expensive only for reasoning — never expose the choice to users."
---

## Analogy

A restaurant kitchen: the salad station doesn't run the grill, and the grill doesn't plate desserts. Each task goes to the station built for it. Customers never see the stations — they just get the dish.

## When it applies

- Multi-stage pipelines with stages of varying complexity
- Apps where ≥10x cost differential between models affects the bottom line
- Classification + reasoning workflows where classification is 90% of calls
- Systems processing thousands of items/day

## When it doesn't

- Single-call simple apps (routing overhead > win)
- When the cheap model's accuracy tanks and you re-process more than you save
- MVPs where speed to market matters more than per-call cost
- User-facing features where users should pick (rare; usually a design smell)

## Primary force

Not all tokens are equal. A classification task that Haiku handles with 98% accuracy costs ~3x less than Sonnet and ~15x less than Opus. Routing automatically by task type (not by user choice) means cost scales with problem complexity rather than uniformly per request. The routing decision is made by the system; exposing model choice to users pushes architectural decisions into the UX layer where they don't belong.

## Common mistakes

- Letting users pick the model (they optimize for the wrong axis, e.g., "best quality" for trivial tasks)
- Routing based on user tier instead of task complexity (monetization leaking into architecture)
- Not measuring per-task accuracy on the cheap model before committing to routing
- Hard-coding model names in business logic — use a config file or router module

## Evidence a topic touches this

- Keywords: Haiku, Sonnet, Opus, model routing, classifier model, cheap model
- Files: `**/model_router*`, `**/config/*.yaml`, `**/routing*`
- Commit verbs: "route to Haiku", "switch model for", "use cheap classifier", "escalate to Sonnet"

## Deeper reading

- User value U6 (Route by Task, Not by User)
- `refrepos/docs/arch-ref-lib/docs/agent-engineering/001-architecture-taxonomy.md` (Pattern B)
