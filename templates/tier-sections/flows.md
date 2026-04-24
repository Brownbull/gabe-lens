# Section: Flows

**Trigger tag:** `mockup-flows`

**Purpose:** User-flow enumeration + walkthrough artifacts for mockup projects. Governs completeness: every REQ that implies a user journey has a flow doc, every flow has entry → steps → exit, error + empty + offline states documented once per flow.

## Dimensions (4)

| Dimension            | MVP                  | Δ(M→E) | Enterprise           | Δ(E→S) | Scale               |
|----------------------|----------------------|--------|----------------------|--------|---------------------|
| Flow enumeration     | happy path per flow  | M      | + error paths        | M      | + empty/offline     |
| Error paths          | inline msg           | M      | + recover action     | M      | + retry telemetry   |
| Empty states         | generic              | S      | + per-flow copy      | M      | + illustrate + CTA  |
| Offline / i18n       | none                 | M      | + offline banner     | M      | + sync + i18n       |

## Notes

- **Flow enumeration:** MVP = one walkthrough HTML per flow, happy-path only. Enterprise = + alternate paths (error recovery, branch points). Scale = + empty + offline + i18n variants in same flow doc, state matrix explicit.
- **Error paths:** MVP = inline error message shown at step. Enterprise = + user-recoverable action (retry, edit, skip). Scale = + telemetry hook + "what went wrong" copy + error-type differentiation.
- **Empty states:** MVP = generic "no data" copy. Enterprise = + per-flow contextualized copy (e.g., "No receipts yet — escanea tu primer recibo"). Scale = + illustration + clear CTA + progressive onboarding.
- **Offline / i18n:** MVP = none (assume online, one language). Enterprise = + offline banner shown when disconnected. Scale = + sync UX (queued actions, reconcile on reconnect) + i18n switch preview in flow.

## Tier-cap enforcement

- **MVP phase:** alternate-path branches or error-recovery actions trigger Enterprise escalation.
- **MVP phase:** offline banner / sync UX triggers Scale escalation.
- **Enterprise phase:** i18n preview + per-locale flow variants trigger Scale escalation.

## Known drift signals

| Pattern                                        | Tier floor | Finding severity |
|------------------------------------------------|------------|------------------|
| Multiple paths / branch points in flow HTML    | Enterprise | TIER_DRIFT-LOW   |
| Retry / recover button in error state          | Enterprise | TIER_DRIFT-LOW   |
| Per-flow empty-state illustration              | Scale      | TIER_DRIFT-LOW   |
| Offline banner component referenced in flow    | Scale      | TIER_DRIFT-MED   |
| `lang=` attribute or i18n switcher in flow     | Scale      | TIER_DRIFT-MED   |
| Flow step numbered >10 without sub-flows       | MVP        | TIER_DRIFT-LOW   |

## Red-line items

- **Coverage invariant.** Every REQ that maps to a user journey MUST have a flow doc. `/gabe-mockup` M4 phase enumerates REQ→flow mappings in `INDEX.md §2 Workflows`. Missing flow for a committed REQ = coverage gap, surfaced at `/gabe-commit` CHECK 7 Layer 4.
