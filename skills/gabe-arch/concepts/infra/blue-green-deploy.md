---
id: blue-green-deploy
name: Blue / Green Deployment
tier: intermediate
specialization: [infra]
tags: [deployment, zero-downtime, rollback, canary]
prerequisites: [load-balancer-basics, health-checks-liveness-readiness]
related: [schema-evolution-expand-contract]
one_liner: "Two identical production environments — deploy to the inactive one, flip traffic when green."
---

## Analogy

Two rooms prepared for a dinner party: the current one (blue) has guests eating; the second (green) is set up fresh with the new menu. You move guests over when green is ready. If something's wrong with the new menu, guests move back to blue instantly — you didn't tear down blue.

## When it applies

- Production services where downtime during deploys is unacceptable
- Rollback requirements (pre-deploy state must be recoverable in seconds)
- Deploy verification windows (run smoke tests on green before flipping)
- Teams with mature infra (two environments double the cost when idle)

## When it doesn't

- Budget-constrained systems where idle green is too expensive (use rolling deploy instead)
- Stateful systems where the two environments can't easily share state (DB migrations in flight)
- Systems with external integrations that assume one environment (webhook sources, etc.)

## Primary force

Rolling deploys update instances one at a time — fast rollback is hard because old and new code run simultaneously for the whole deploy window. Blue/green keeps two complete environments: old (blue) serves traffic; new (green) is deployed, smoke-tested, and flipped atomically at the LB. Rollback is just flipping back, so the blast radius of a bad deploy is seconds, not minutes. The cost is doubled infrastructure during the deploy window.

## Common mistakes

- Shared database without expand/contract migrations (blue breaks when green adds a column)
- No smoke tests on green before the flip (you discover the bug after traffic arrives)
- Keeping blue running for hours "just in case" (pay for double capacity indefinitely)
- Flipping traffic all at once instead of canarying (blue/green + canary is the gold standard)
- No plan for stateful connections (WebSockets on blue don't gracefully migrate)

## Evidence a topic touches this

- Keywords: blue green, canary, deploy, zero-downtime, cutover, traffic shift
- Files: `**/deploy/*`, `**/terraform/*`, `**/ci/*`
- Commit verbs: "blue/green deploy", "shift traffic", "flip to green", "roll back to blue"

## Deeper reading

- Martin Fowler: "BlueGreenDeployment"
- AWS CodeDeploy blue/green docs
- Netflix's canary analysis: Spinnaker + Kayenta
