# P3 — async-listener-race

## Evidence source

Gastify `docs/rebuild/LESSONS.md` §2 Seam A → rule R5. BoletApp `usePendingScan` opened its Firestore `onSnapshot` listener AFTER the server-side scan wrote the result — missing the state change. UI never refreshed. Marked `memory/scan-fix-handoff.md` as INCOMPLETE. Repeatedly band-aided.

## Red-line questions

- For every async delivery path where a server event may fire "at any time": does the client have BOTH a push listener AND a pull-catchup path?
- Does the listener subscribe on a stable identity (user session, app instance) that exists BEFORE any event could fire — or does subscription depend on an ID that only arrives after the event?
- If the subscription drops (mobile backgrounding, transient disconnect), is there a deterministic recovery path that does not depend on another listener?

## Detection — doc pass

- `.kdbp/DECISIONS.md`: ADR describing async delivery protocol. Look for keywords: SSE, WebSocket, onSnapshot, pub-sub, listener.
- `docs/rebuild/LESSONS.md` or `RULES.md`: existing R-rule on dual-path (push + pull) delivery?
- Mockup `HANDOFF.json`: any annotation saying "wait for server" / "loading" on a flow that has no fallback pull?

## Detection — code pass

- Grep `onSnapshot|addEventListener|EventSource|\.subscribe\(` inside a `useEffect` whose dep list includes an ID fetched asynchronously earlier in the same effect.
- Pattern: `useEffect(() => { const id = await fetch(...); subscribe(id, ...); }, [])` — the `await` creates the race.
- Check `GET /api/.../<resource>/:id` endpoint coverage: if the resource is push-delivered, is there also a pull endpoint that returns current status unconditionally?
- Firestore-specific: `onSnapshot` calls that don't have a corresponding `.get()` catch-up path.

## Detection — commit pass

- `/listener never fires/i`
- `/fix.*refresh|refresh.*fix/i`
- `/refetchOnMount|refetchInterval/i` (often added as band-aid for P3)
- `/subscription race|race condition/i`
- `/INCOMPLETE|incomplete fix/i`

## Tier impact

- MVP: surfaces if there is a user-facing async flow (scan, upload, AI processing, payment webhook) with single-path delivery.
- Enterprise: all async delivery paths must have dual paths (push + pull).
- Scale: plus reconnection strategy + backfill.

## Severity default

CRITICAL (this pattern's incident shape is "works in dev, breaks in the wild" — a trust killer).

## ADR stub template

**Decision:** Async result delivery for `<resource>` uses dual paths: **push** (SSE / WebSocket / onSnapshot) as primary; **pull** (`GET /<resource>/:id`) as idempotent fallback. UI triggers pull on subscription gaps (mobile backgrounding, reconnect, visibility change).
**Rationale:** Gastify LESSONS R5. Push-only delivery fails when the listener subscribes after the event; pull is the deterministic recovery.
**Alternatives considered:**
1. Push-only with aggressive reconnect — rejected; doesn't solve the catchup gap.
2. Pull-only with short interval — rejected; wastes reads, increases cost (see P10).

## Open Question template

**Question:** For `<resource>`, does the client have a pull endpoint that returns current state regardless of subscription status? What triggers fallback pull (reconnect, visibility change, user action)?

## Rule template

**Rule:** Every server-pushed async result has a pull-fallback endpoint. UI triggers pull on: initial subscription, reconnect, tab visibility regain, and any user action that requires the result.
**Detection:** integration test that disables push (SSE/onSnapshot) and asserts the UI still sees the result via pull. CI fails on missing test per resource.
