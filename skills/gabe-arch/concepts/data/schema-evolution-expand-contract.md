---
id: schema-evolution-expand-contract
name: Schema Evolution — Expand / Migrate / Contract
tier: intermediate
specialization: [data]
tags: [migration, schema, zero-downtime, expand-contract]
prerequisites: []
related: [api-versioning-strategies]
one_liner: "Never break old readers — add new, migrate, then remove old, across three deploys."
---

## Analogy

Widening a highway without stopping traffic: you build the new lanes beside the old, open them in parallel, route traffic over, then close the old lanes. The road never closes; only the layout changes.

## When it applies

- Any live database with deployed code that reads from it
- Renaming columns, changing types, restructuring tables
- API response shape changes that have active clients
- Anywhere "downtime for migration" is unacceptable

## When it doesn't

- Brand-new systems with no deployed readers (just write the target schema)
- Single-deploy systems where you fully control read and write at the same time
- Tiny datasets where a maintenance window is cheaper than the choreography

## Primary force

A rename that happens in one deploy — `ALTER TABLE users RENAME COLUMN email_addr TO email` — breaks every running instance of the old code reading from it. Expand/migrate/contract splits the change into three safe deploys: **(1) Expand:** add the new column, have code write to both; **(2) Migrate:** backfill the new column, flip reads to it; **(3) Contract:** remove the old column after all code is updated. Each step is reversible until the contract phase.

## Common mistakes

- Skipping the expand step (doing rename + code change atomically in one deploy — works until it doesn't)
- Never executing the contract step (you end up with both columns forever, confusion for everyone who reads the schema)
- Data backfill without batching (long-running transaction locks the table)
- No feature flag between "writes to both" and "reads from new" (atomic switch = risk)

## Evidence a topic touches this

- Keywords: expand contract, zero-downtime migration, schema migration, backfill, dual-write
- Files: `**/migrations/*`, `**/alembic/*`, `**/db/schema*`
- Commit verbs: "add column", "backfill", "drop old column", "dual-write"

## Deeper reading

- Stripe Engineering: "Online migrations at scale"
- GitHub Engineering: "gh-ost" (large table migration tooling)
- "Refactoring Databases" by Ambler & Sadalage
