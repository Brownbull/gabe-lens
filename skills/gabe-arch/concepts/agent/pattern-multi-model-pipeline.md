---
id: pattern-multi-model-pipeline
name: "Pattern B: Multi-Model Staged Pipeline"
tier: intermediate
specialization: [agent, cost]
tags: [pattern, pipeline, cost-optimization, model-routing]
prerequisites: [pattern-single-agent-pipeline, model-routing-by-task]
related: [pattern-state-machine, structured-output-enforcement]
one_liner: "Different models at different stages — cheap for sorting, expensive only for reasoning."
---

## Analogy

A hospital intake: a nurse checks you in (cheap), a triage nurse decides urgency (cheaper), a specialist sees you only when needed (expensive). You never pay a surgeon to take your temperature.

## When it applies

- Per-incident cost is load-bearing (high volume, thin margin)
- Task decomposes cleanly into cheap-to-classify + expensive-to-reason-about stages
- You have measured costs of each stage and the split is 10x+ favorable
- Production systems processing thousands of items/day

## When it doesn't

- MVPs where cost isn't yet a concern (Pattern A is faster to ship)
- Tasks where the cheap model routinely misroutes and you end up re-processing
- Latency budget <5s (stage-to-stage overhead adds up)

## Primary force

One expensive model per request is the wrong answer when 90% of requests only need a cheap classifier. Multi-model pipelines route each stage to the minimum-capability model that can do the job, so cost scales with complexity rather than volume. Team #2's production system ran at $0.007/incident using 5 models where a single Claude call would have cost $0.05+.

## Common mistakes

- Routing to the cheap model for everything and hoping it generalizes (it doesn't)
- Not measuring per-stage cost/accuracy — you can't optimize what you don't measure
- Splitting into more stages than needed (each boundary is a serialization + overhead cost)
- Hard-coding model choices; prefer config so routing can evolve

## Evidence a topic touches this

- Keywords: model routing, Haiku, Sonnet, multi-model, classifier, cheap classify
- Files: `**/model_router.*`, `**/classifier.py`, `**/stages/*`
- Commit verbs: "route to", "switch to Haiku", "classify with cheap model"

## Deeper reading

- `refrepos/docs/arch-ref-lib/docs/agent-engineering/001-architecture-taxonomy.md` (Pattern B section)
- User value U6 (Route by Task, Not by User)
