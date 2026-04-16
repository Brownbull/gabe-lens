# Human Knowledge Map

<!-- Tracks what the human (operator/architect) understands about decisions made. -->
<!-- Populated and updated by /gabe-teach. -->
<!-- Goal: the human knows WHY/WHEN/WHERE, not HOW. Architect-level, not coder-level. -->

## Gravity Wells

<!-- Architectural sections of the app. Topics anchor to a primary well. -->
<!-- Soft cap: 7 wells (Miller's number). -->
<!-- A topic that spans wells gets one primary Well + `cross` in the Tags column. -->
<!-- G0 Uncategorized is a reserved fallback for orphan topics; /gabe-teach flags it. -->

**Status: uninitialized.** Run `/gabe-teach init-wells` to define architectural sections before the first teach session.

<!-- Analogy column: one-liner (5-15 words) from gabe-lens. Makes each well graspable at a glance. -->
<!-- Generated at init-wells time; can be regenerated via /gabe-teach wells. -->

| # | Name | Description | Analogy | Topics (verified / pending / total) |
|---|------|-------------|---------|--------------------------------------|

## Topic Classes

| Class | Question it answers | Source |
|-------|--------------------|--------|
| **WHY** | Why did we choose this approach? | commits, PLAN.md, DECISIONS.md |
| **WHEN** | When to apply / not apply this pattern? | repeated patterns across commits |
| **WHERE** | Why does this file live here? (static gravity well) | new files + project structure conventions |

## Status Lifecycle

| Status | Meaning | Re-surfaces? |
|--------|---------|--------------|
| `pending` | Detected from changes, not yet discussed | Yes, next /gabe-teach |
| `verified` | Human answered quiz correctly (score recorded) | No, unless stale |
| `skipped` | Human deferred this session | Yes, next /gabe-teach |
| `already-known` | Human claimed prior knowledge | No |
| `stale` | Verified >90 days ago | Yes, for refresh |

## Topics

| # | Well | Class | Topic | Status | Tags | Last Touched | Verified Date | Score | Source |
|---|------|-------|-------|--------|------|--------------|---------------|-------|--------|

<!-- Example rows:
| T1 | G1 | WHY | Why guardrails run before the LLM | verified |  | 2026-04-17 | 2026-04-17 | 2/2 | a4c9e2f |
| T2 | G3 | WHY | Why 202 Accepted + BackgroundTask | pending |  | 2026-04-17 | — | — | b1d8e3a |
| T3 | G5 | WHY | Structured logging format choice | pending | cross | 2026-04-17 | — | — | c7f2a91 |
-->

## Sessions

<!-- Append-only log of /gabe-teach runs. Enriched with wells active + plan/phase reference. -->

<!-- Example:
### 2026-04-17 — /gabe-teach topics (post-commit)
- Wells active: G1 Guardrails, G2 LLM Pipeline, G3 API Layer, G4 Frontend, G5 Observability
- Commits covered: a4c9e2f, b1d8e3a, c7f2a91
- Plan reference: .kdbp/PLAN.md — "Phase 1 Level 2a" (current phase 3 of 5)
- Presented: T1, T2, T3
- Verified: T1 (score 2/2)
- Skipped: T2
- Already-known: T3 (sanity-checked)
-->

## Storyline

<!-- Generated on demand by /gabe-teach story. Lossy analogy of what's been built and why. -->
<!-- Auto-refresh trigger: 3 new archived plans since last generation. Manual: /gabe-teach story refresh. -->

No storyline generated yet. Run `/gabe-teach story` after a few completed phases to generate one.
