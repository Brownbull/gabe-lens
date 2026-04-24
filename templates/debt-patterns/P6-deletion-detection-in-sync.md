# P6 — deletion-detection-in-sync

## Evidence source

BoletApp `docs/sprint-artifacts/epic-14c-retro-2026-01-20.md` §1. Delta sync (fetching changes since last sync) could NOT detect *removals* by design — you can see new / modified data, but not "what's missing." When User A untagged a transaction from a shared group, User B still saw it. Attempted fixes (`removedFromGroupIds`, count-based detection) each compounded complexity. `deletedAt?: Timestamp` field was designed in the schema but propagation was never wired. Epic 14c was **reverted after 3 days**.

## Red-line questions

- For every multi-user sync / delta-fetch path: are deletions propagated via tombstones (soft-delete markers with timestamp) — not via absence-from-result?
- Does the client sync logic distinguish "missing because deleted" from "missing because filtered"?
- Is there a test that deletes on client A and asserts client B sees the removal within a bounded time?

## Detection — doc pass

- `.kdbp/ENTITIES.md`: entities with sync / multi-user semantics — do they have a `deleted_at` / `tombstone_at` / `removed_at` field?
- `.kdbp/DECISIONS.md`: ADR on deletion semantics for sync (hard vs soft, tombstone TTL, GC policy).
- `.kdbp/SCOPE.md §14`: open questions about multi-user consistency.

## Detection — code pass

- Grep sync code for `lastSyncAt|since=|updatedAfter=` — if present, check for corresponding tombstone / soft-delete handler: `deletedAt|deleted_at|tombstone|removed_at`.
- Pattern: delta fetch that unions remote results into local cache WITHOUT subtracting missing items (naïve merge).
- Firestore-specific: `onSnapshot` that only handles `added` + `modified` change types but not `removed`.
- REST / WebSocket sync: is there a `deleted_ids` array in the payload, or does the client infer absence?

## Detection — commit pass

- `/delta sync|incremental sync/i` without matching tombstone/deletion commits
- `/refetchOnMount|refetch on mount/i` (often added as band-aid for delete-detection failure — see also P8)
- `/can'?t detect .* removed|removal detection/i`
- `/untag|unshare|remove from group/i` followed by `/still shows|phantom|stale/i`
- `/revert.*sync|reverted .* shar/i`

## Tier impact

- MVP: surfaces if the app has ANY multi-user sync (shared state, collaboration, real-time).
- Enterprise: plus: CRITICAL if no tombstone field + no integration test for cross-client deletion.
- Scale: plus: tombstone GC policy required.

## Severity default

CRITICAL (this is the BoletApp Epic 14c killer).

## ADR stub template

**Decision:** Deletion in sync uses tombstones: each syncable entity has `deleted_at` (nullable timestamp). Clients filter `deleted_at IS NULL` for the normal view but receive tombstones via delta sync so they can remove from local cache. Tombstones are GC'd after `<retention>` days.
**Rationale:** BoletApp Epic 14c reverted after 3 days because delta sync cannot detect removals by design. Tombstones are the standard fix; skipping them compounds into cascading band-aids (`refetchOnMount`, count-based detection, cost explosion).
**Alternatives considered:**
1. `removedFromGroupIds` array per user — rejected; BoletApp tried it, never fully wired, compounded complexity.
2. `refetchOnMount: true` as fallback — rejected; O(all × navigations) cost (see P10).
3. Hard delete + broadcast event — only viable if every client guaranteed online; see P3 for why event-only is fragile.

## Open Question template

**Question:** For sync-enabled entities `<X, Y, Z>`, how are deletions propagated across clients? Tombstone field + TTL? Broadcast event + pull fallback? Absence-from-result?

## Rule template

**Rule:** Every syncable entity has a `deleted_at` tombstone field. Delta sync payloads carry tombstones explicitly. Integration test: delete on client A, assert client B removes within N seconds (configurable).
**Detection:** entity schema audit (every synced entity declares `deleted_at`); CI integration test per entity.
