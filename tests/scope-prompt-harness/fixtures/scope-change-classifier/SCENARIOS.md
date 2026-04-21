# Scope-Change Classifier — 23 Fixture Scenarios (v2)

**Status:** 5 scenarios have physical fixtures; the remaining 18 are reference specs for real-LLM validation in Phase 3.5 or Phase 6 DoD (≥95% correctness gate before shipping `/gabe-scope-change`).

**Rule set:** v2 — added rules 6-conflict (new authoritative ref contradicts existing decisions), 8 (constraint infeasibility), 9 (timeline compression forces phase skipping). Rule 6 now covers both replace/downgrade AND conflicting new refs.

This doc is the canonical 20-scenario test suite for the classifier. Physical fixtures cover the canonical pivot triggers + one clean addition. The other 15 scenarios exercise edge cases, borderline calls, and user-intent mismatches.

## Legend

- **Expected:** `pivot` | `addition`
- **Rule:** expected `trigger_rule` value
- **Confidence:** expected LLM confidence (`high` | `medium` | `low`)

## Physical fixtures (5)

| # | Scenario | Expected | Rule | Confidence |
|---|---|---|---|---|
| 1 | `primary-user-change` | pivot | primary_user | high |
| 2 | `new-req-addition` | addition | none | high |
| 3 | `non-goal-becomes-goal` | pivot | goal_flip | high |
| 4 | `ref-downgrade` | pivot | ref_downgrade | high |
| 5 | `architecture-shift` | pivot | posture_shift | high |

## Reference-only (15 — authored for real-LLM validation)

| # | Scenario | Expected | Rule | Confidence | Change description |
|---|---|---|---|---|---|
| 6 | `secondary-becomes-primary` | pivot | primary_user | high | A Secondary User is promoted to Primary |
| 7 | `non-user-promoted` | pivot | non_user_flip | high | A declared Non-User becomes Secondary |
| 8 | `sc-removed` | pivot | sc_change | high | SC-02 deleted |
| 9 | `sc-inverted` | pivot | sc_change | high | SC-01 ("under 60s") becomes ("under 10 minutes") |
| 10 | `goal-becomes-non-goal` | pivot | goal_flip | high | SC-03 removed and added as NG-04 |
| 11 | `sync-to-async-flip` | pivot | posture_shift | medium | sync-first to async-first (not just addition of async endpoints) |
| 12 | `monolith-to-multi-agent` | pivot | posture_shift | high | architecture topology shift |
| 13 | `new-sc-tightening` | addition | none | high | New SC added that refines an existing REQ's acceptance signal |
| 14 | `new-ref-authoritative` | addition | none | high | New authoritative ref added (not replacing existing) |
| 15 | `contextual-ref-removed` | addition | none | high | Removing a contextual ref |
| 16 | `new-phase-inserted` | addition | none | high | New phase inserted between Phase 2 and 3 at decimal ID 2.1 |
| 17 | `constraint-tightened` | addition | none | high | Budget tightened from $20/mo to $10/mo |
| 18 | `constraint-relaxed-posture-stable` | addition | none | medium | Budget relaxed without changing posture — borderline but not a pivot |
| 19 | `business-model-pivot` | pivot | business_model | high | Free-to-self → paid SaaS; retargets the product |
| 20 | `double-change-masking-pivot` | pivot | primary_user | medium | User claims "just adding features" but one feature changes primary user segment; test that classifier surfaces the hidden pivot |
| 21 | `new-auth-ref-conflicts-stack` | pivot | ref_conflict | high | New authoritative auth-framework ref added that contradicts the already-chosen stack — exercises the v2 expansion of rule 6 |
| 22 | `budget-compressed-to-infeasibility` | pivot | constraint_infeasibility | high | Budget cut from $1M/yr to $1k/yr with existing SCs assuming ML infra — SCs become infeasible even if not explicitly removed |
| 23 | `timeline-forces-phase-skip` | pivot | timeline_compression | medium | Deadline pulled in 6 months, forcing Phase 5 to be dropped entirely — structural roadmap change, not just acceleration |

## Acceptance gate (for Phase 6 DoD)

Before `/gabe-scope-change` ships, classifier must achieve **≥95% correct classification** against the 23 scenarios (22/23 minimum). Misclassifications must be documented with remediation prompt tweaks.
