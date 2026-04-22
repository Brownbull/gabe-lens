# Tier Δ Grading Scale

Δ columns in tier trade-off matrices grade the **risk magnitude** of skipping a tier upgrade. Answers: "If I stay at lower tier and this phase ships to prod, how bad is the consequence?"

## Scale

| Grade | Label     | Meaning                                                                 |
|-------|-----------|-------------------------------------------------------------------------|
| S     | small     | Cosmetic, rarely bites. User might never notice. Cheap retrofit.        |
| M     | medium    | Noticeable, recoverable. Degraded experience. Workaround exists.        |
| L     | large     | User-visible incident. Costly retrofit. May need PR postmortem.         |
| XL    | critical  | Data loss, security breach, outage risk. Existential for the feature.   |

## Prototype-tag shift

Phases tagged `prototype: true` shift all Δ grades down one notch automatically:

| Original | Shifted |
|----------|---------|
| XL       | L       |
| L        | M       |
| M        | S       |
| S        | S (floor) |

**When to tag prototype:**
- Hackathon demo, proof-of-concept
- Internal admin script, dev-only tool
- Throwaway code you'll delete after validation
- Feature flag experiment at <1% rollout

**When NOT to tag prototype:**
- Any phase that will see real users or real data
- Any code that will survive into the next phase as-is
- Migrations, auth, payment, PII handling (never prototype-tag these)

The shift encodes: "consequences are smaller because stakes are smaller." Escapable via explicit escalation at execute time.

## Grading procedure

1. **Catalog default.** Each section file ships with default Δ per row. Based on typical production-grade risk.
2. **LLM override per phase.** `/gabe-plan` may re-score Δ if phase context changes risk. Reason logged to DECISIONS.md.
3. **`/gabe-review` TIER_DRIFT.** Uses stored Δ at time of phase planning. Drift finding references the Δ that was accepted.

## Per-phase worked example

Phase: `AI triage agent` — types: `[ai-agent, integration]`, tier: `mvp`

Accepted trade-offs (Δ ≥ L on MVP→Ent skip):

| Dimension               | Section    | Δ(M→E) | Consequence of staying MVP                        |
|-------------------------|------------|--------|---------------------------------------------------|
| Testing                 | Core       | L      | Bug in edge case ships undetected                 |
| Error handling          | Core       | L      | User sees uncaught LLM 5xx as stack trace         |
| Structured output (U4)  | AI/Agent   | XL     | Triage returns malformed JSON, pipeline crashes   |
| Idempotency             | Integration| XL     | Duplicate LLM calls on retry burn budget + wrong state |

MVP tier = ship fast, accept those four. XL items are the highest-stakes bets. Prototype-tag would shift XL→L. Without prototype tag, XL items are load-bearing — phase can't quietly escalate past them without DECISIONS.md entry.

## Rendering

Δ columns render as bare letter + whitespace pad to 6-char width: `L     `, `XL    `, `S     `.

Never render `L (large)` inline — too wide. Legend at table top or footer link instead.

## Floor + ceiling rules

- **Floor: S.** No Δ below S — sub-S means "no meaningful difference," which means the dimension shouldn't be a row.
- **Ceiling: XL.** No Δ above XL — XL already means existential. No "XXL."

If a dimension genuinely has no gap between tiers (identical cell content MVP/Ent/Scale), drop the row — don't render `S/S` across tier jumps.
