# P10 — cost-model-absent-before-deploy

## Evidence source

BoletApp `docs/sprint-artifacts/epic-14c-retro-2026-01-20.md` §3. The `refetchOnMount: true` fallback's $30/day / 1K-user projection was computed **after** the incident. No cost-monitoring dashboard existed at ship time. Band-aid was deployed without economic modeling. Paired with P8 (silent fallback changes big-O) but distinct — P10 is about systemic absence, P8 is about a specific flag change.

## Red-line questions

- Does the project have a per-user cost target (reads, writes, $ / user / month)?
- Is there a cost dashboard (Firebase Analytics, Supabase dashboard, custom) that tracks actual vs projected?
- Does any feature ship touching quota-metered resources (Firestore, LLM calls, paid APIs) without a `# cost:` annotation in the PR or design doc?

## Detection — doc pass

- `.kdbp/SCOPE.md §9 Constraints`: does Budget section specify $/user/month or total monthly budget?
- `.kdbp/DECISIONS.md`: any ADR on cost monitoring / alerting?
- `docs/` or `README.md`: dashboard URL, runbook, cost note?
- `.kdbp/BEHAVIOR.md`: rate-limit declarations (a rate limit implies a cost model).

## Detection — code pass

- Grep `generativeModel|openai|anthropic` — count of LLM call sites. Flag if none have a cost comment or counter.
- Grep `firestore().collection.*get()|firestore().collection.*onSnapshot` — unfiltered reads on unbounded collections.
- Check for rate-limit middleware: `express-rate-limit`, `@upstash/ratelimit`, custom token buckets. If absent on quota-metered endpoints, flag.
- Grep `.env` for budget / quota / limit variables.
- Look for `// cost:` / `# cost:` / `BUDGET:` annotations. Absence across the whole repo = CRITICAL.

## Detection — commit pass

- `/cost explosion|cost spike|runaway/i`
- `/budget|quota/i` in commits ADDING features without a `# cost:` comment in the diff
- Post-incident patterns: `/reduce reads|optimize cost|cut reads/i` commits suggest cost-after-the-fact.

## Tier impact

- MVP: surfaces if ANY quota-metered backend is used AND no cost target / dashboard is declared.
- Enterprise: plus: every new feature touching quota-metered resources must include a cost estimate in the PR.
- Scale: plus: automated cost-delta detection on PR (diff against baseline).

## Severity default

HIGH (less CRITICAL than P8 because this is systemic absence, not an actively-hemorrhaging flag — but it's the upstream cause of P8 incidents).

## ADR stub template

**Decision:** The project maintains a cost model at `<path>`: per-user targets (reads, writes, LLM tokens, $/user/month) and aggregate budget ceiling. A dashboard tracks actuals. Every new feature touching quota-metered resources includes a `# cost:` section in its PR with projected delta.
**Rationale:** BoletApp Epic 14c §3. Without a cost model, silent-fallback band-aids (P8) go undetected until they've hit runaway scale.
**Alternatives considered:**
1. Monitor-after-launch — rejected; $30/day blast radius is unrecoverable once live.
2. Rate-limiting only — partial; doesn't catch systemic under-pricing.

## Open Question template

**Question:** What's the project's per-user cost target for `<resource: reads / writes / LLM tokens / paid API>`? Where is the dashboard? Where are PR cost annotations required?

## Rule template

**Rule:** Project maintains a cost model document at `.kdbp/COST-MODEL.md` (or referenced doc). Every PR touching quota-metered resources includes a `# cost:` comment with reads/writes × users × $/op and projected delta. CI fails when diff touches listed quota surfaces without the comment.
**Detection:** CI script grepping for flagged-surface patterns in diff + requiring PR-body cost section.
