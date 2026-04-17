---
id: health-checks-liveness-readiness
name: "Health Checks: Liveness vs Readiness"
tier: foundational
specialization: [infra]
tags: [health-check, liveness, readiness, kubernetes, lb]
prerequisites: []
related: [load-balancer-basics, blue-green-deploy]
one_liner: "Liveness asks 'are you alive?'; readiness asks 'are you ready for traffic?' — different answers, different actions."
---

## Analogy

A restaurant at opening time. **Liveness** = "is the chef breathing?" (if no, call someone; restart them). **Readiness** = "has the kitchen finished setup — stoves on, ingredients prepped?" (if no, don't seat customers yet but don't replace the chef). Conflating them means you replace a chef who's just slow to set up.

## When it applies

- Any containerized deployment (Kubernetes, ECS, Nomad)
- Services behind a load balancer that can drop unhealthy backends
- Rolling deploys where new instances need a warmup period
- Services with slow-starting dependencies (DB connection pool, cache warm, config load)

## When it doesn't

- Truly stateless, instant-start services (readiness and liveness collapse to the same check)
- One-off batch jobs (no traffic to route)

## Primary force

"Is this instance alive?" and "should the LB send traffic to it?" are different questions with different correct responses. **Liveness failure** → the orchestrator kills and restarts the container (drastic). **Readiness failure** → the LB stops routing traffic temporarily (gentle; instance stays alive to finish warming up). Without the distinction, a slow-startup service gets killed mid-warmup and never actually becomes ready.

## Common mistakes

- Same endpoint for liveness and readiness (deep dependency checks cause restart loops when a dependency flaps)
- Liveness check queries the DB (DB outage → everyone restarts simultaneously → cascading failure)
- Readiness check is just `return 200` (LB sends traffic to instances that can't actually serve)
- No startup probe (Kubernetes) — readiness fails too aggressively during slow starts
- Health endpoint auth-gated (LB can't reach it; infinite restart loop)

## Evidence a topic touches this

- Keywords: liveness, readiness, health check, /healthz, startup probe, livenessProbe
- Files: `**/health*`, `**/kubernetes/*`, `**/deploy/*.yaml`
- Commit verbs: "add health check", "liveness probe", "readiness endpoint", "/healthz"

## Deeper reading

- Kubernetes docs: Liveness, Readiness, and Startup Probes
- "Site Reliability Engineering" (Google) ch. 22
