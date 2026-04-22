# Section: UI/UX

**Trigger tag:** `user-facing`

**Purpose:** Rendering posture, accessibility, streaming feedback. Applies to phases that ship code a human end-user will interact with.

## Dimensions (4)

| Dimension            | MVP                  | Δ(M→E) | Enterprise           | Δ(E→S) | Scale               |
|----------------------|----------------------|--------|----------------------|--------|---------------------|
| Loading states       | none                 | M      | spinner/skeleton     | S      | + optimistic render |
| Error states         | alert                | L      | inline + recover     | M      | + retry UI + report |
| A11y                 | none                 | M      | semantic HTML        | L      | + ARIA + keyboard   |
| Streaming (U5)       | none                 | L      | SSE basic            | M      | + token + cancel    |

## Notes

- **Loading states:** MVP = blank screen while fetching. Enterprise = spinner/skeleton after 200ms. Scale = optimistic render with server reconciliation.
- **Error states:** MVP = raw `alert()` or generic error toast. Enterprise = inline error with user-recoverable action (retry button, reset form). Scale = retry UI + telemetry error report path.
- **A11y:** MVP = none (divs everywhere). Enterprise = semantic HTML (button vs div, label vs placeholder, proper heading hierarchy). Scale = + ARIA roles + full keyboard navigation + screen-reader testing.
- **Streaming (U5):** Ties to U5 value (Stream the Thinking). MVP = none, user stares at frozen UI during 30s AI call. Enterprise = SSE with basic token/chunk rendering. Scale = full token stream + cancel button + progress.

## Tier-cap enforcement

- **MVP phase:** ARIA attributes, full keyboard nav, or screen-reader test hooks trigger escalation prompt.
- **MVP phase:** SSE / WebSocket client scaffolding for streaming triggers escalation.
- **Enterprise phase:** cancel-token UX for in-flight streams triggers Scale escalation.

## Known drift signals

| Pattern                                        | Tier floor | Finding severity |
|------------------------------------------------|------------|------------------|
| `aria-*` attributes on 3+ elements             | Enterprise | TIER_DRIFT-LOW   |
| Keyboard shortcut registry / focus trap        | Scale      | TIER_DRIFT-MED   |
| Optimistic update + rollback pattern           | Scale      | TIER_DRIFT-MED   |
| Error boundary with telemetry report           | Enterprise | TIER_DRIFT-LOW   |
| SSE client / `EventSource` subscription        | Enterprise | TIER_DRIFT-MED   |
| Cancel-token + AbortController on stream       | Scale      | TIER_DRIFT-MED   |

## Red-line items

- **U5 streaming on long AI calls.** Any user-facing phase where AI processing > 5 seconds MUST show streaming feedback. `none` in Streaming row is NOT acceptable — force Enterprise minimum. `/gabe-plan` should flag if AI-agent tag + user-facing tag coexist on an MVP phase with Streaming = `none`.
