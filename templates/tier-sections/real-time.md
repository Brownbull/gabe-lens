# Section: Real-time

**Trigger tags:** `realtime`, `streaming`, `sse`

**Purpose:** Real-time communication posture. Applies to phases using WebSocket, SSE, long-polling, or any persistent connection stream.

## Dimensions (5)

| Dimension            | MVP                  | Δ(M→E) | Enterprise           | Δ(E→S) | Scale               |
|----------------------|----------------------|--------|----------------------|--------|---------------------|
| Reconnection         | manual               | L      | auto exp backoff     | M      | + jitter + budget   |
| Backpressure         | drop                 | L      | buffer + limit       | M      | + flow control      |
| Presence             | none                 | M      | heartbeat            | M      | + server ack        |
| Message order        | best-effort          | L      | seq + ack            | M      | + gap detect + fill |
| Fallback transport   | one only             | M      | SSE+WS fallback      | S      | + long-poll last    |

## Notes

- **Reconnection:** MVP = user reloads page on disconnect. Enterprise = auto reconnect with exponential backoff. Scale = + jitter + total reconnect budget to stop thrashing.
- **Backpressure:** MVP = drop messages when client can't keep up. Enterprise = buffer with size limit + policy (drop-oldest, drop-newest, close). Scale = explicit flow-control protocol (client signals readiness, server paces sends).
- **Presence:** MVP = no idea if client still connected. Enterprise = periodic heartbeat + timeout detection. Scale = server-acknowledged presence + cross-connection liveness signals.
- **Message order:** MVP = assume order-of-arrival = order-of-send (wrong under reconnects). Enterprise = sequence numbers + client ack. Scale = + gap detection with backfill request.
- **Fallback transport:** MVP = only WebSocket (or only SSE) — fails on restrictive networks. Enterprise = WebSocket with SSE fallback. Scale = + long-polling as final fallback.

## Tier-cap enforcement

- **MVP phase:** heartbeat senders, sequence number + ack code, reconnect backoff libraries trigger escalation.
- **Enterprise phase:** gap-detect/backfill protocol, long-polling fallback layer trigger Scale escalation.

## Known drift signals

| Pattern                                      | Tier floor | Finding severity |
|----------------------------------------------|------------|------------------|
| Exponential reconnect (`reconnecting-websocket`) | Enterprise | TIER_DRIFT-MED |
| Server-sent heartbeat + client timeout detection | Enterprise | TIER_DRIFT-MED |
| Sequence number + ack protocol in message envelope | Enterprise | TIER_DRIFT-MED |
| Gap-detection + backfill request handler     | Scale      | TIER_DRIFT-HIGH  |
| Socket.IO / Pusher fallback transport stack  | Scale      | TIER_DRIFT-LOW   |
| Flow-control window protocol (backpressure signaling) | Scale | TIER_DRIFT-HIGH |

## Red-line items

- **Reconnection on user-facing streams.** Any phase shipping a streaming UX to real users needs auto-reconnect at Enterprise minimum. MVP `manual` = user stares at dead UI, reloads, loses state. Acceptable only for developer-tool phases or prototypes.
- **Backpressure on high-volume streams.** If phase involves server→client streams with bursty upstream producers (LLM token streams, live feeds), `drop` without backpressure signaling leads to UX gaps. Escalate if message volume > 10/sec sustained.
