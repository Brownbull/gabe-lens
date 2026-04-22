# Section: Client State

**Trigger tags:** `client-state`, `spa`, `pwa`

**Purpose:** Client-side state management, cache, propagation. Applies to phases touching frontend state stores (TanStack Query, Zustand, Redux, Jotai, Pinia) or client-side cached data.

## Dimensions (7)

| Dimension            | MVP                  | Δ(M→E) | Enterprise           | Δ(E→S) | Scale               |
|----------------------|----------------------|--------|----------------------|--------|---------------------|
| Cache invalidation   | manual refetch       | L      | tag/key invalidate   | M      | + selective + SWR   |
| Optimistic updates   | none                 | M      | rollback on error    | M      | + reconcile merge   |
| Stale data           | hope                 | L      | refetch + TTL        | M      | + SWR + bg poll     |
| Mutation propagation | manual invalidate    | L      | query-key auto       | M      | + subscribe/pubsub  |
| Cross-tab sync       | none                 | M      | storage events       | S      | + shared worker     |
| Offline support      | fail on offline      | L      | read cache           | M      | + write queue       |
| Store coupling       | component state      | M      | scoped Zustand       | S      | + normalizer        |

## Notes

- **Cache invalidation:** MVP = user refreshes to see new data. Enterprise = tag or query-key invalidation after mutation. Scale = selective invalidation + stale-while-revalidate.
- **Optimistic updates:** MVP = await server before updating UI. Enterprise = optimistic apply with rollback on error. Scale = conflict-aware merge (three-way reconcile).
- **Stale data:** MVP = data in cache until explicit refresh. Enterprise = refetch-on-focus + TTL eviction. Scale = stale-while-revalidate with background polling.
- **Mutation propagation:** MVP = component manually invalidates queries. Enterprise = query-key-based auto invalidation (TanStack Query's `invalidateQueries`). Scale = pub-sub or server subscriptions for cross-client propagation.
- **Cross-tab sync:** MVP = per-tab state divergence. Enterprise = `storage` events or BroadcastChannel. Scale = shared worker for coordinated state.
- **Offline support:** MVP = crash on no network. Enterprise = read-through cache. Scale = full offline with write queue + conflict resolution on reconnect.
- **Store coupling:** MVP = all state lives in components (prop drilling). Enterprise = scoped store slices. Scale = normalized store with entity adapter.

## Tier-cap enforcement

- **MVP phase:** optimistic update handlers, cross-tab sync subscriptions, offline write queue all trigger escalation.
- **Enterprise phase:** shared worker registration, normalized entity adapter patterns trigger Scale escalation.

## Known drift signals

| Pattern                                        | Tier floor | Finding severity  |
|------------------------------------------------|------------|-------------------|
| `onMutate` + `onError` rollback in TanStack    | Enterprise | TIER_DRIFT-MED    |
| `BroadcastChannel` / `storage` event listener  | Enterprise | TIER_DRIFT-MED    |
| Shared worker registration                     | Scale      | TIER_DRIFT-HIGH   |
| Service worker with offline queue (Workbox)    | Scale      | TIER_DRIFT-HIGH   |
| Normalized store (`@reduxjs/toolkit createEntityAdapter`, `normalizr`) | Scale | TIER_DRIFT-MED |
| Stale-while-revalidate + `refetchInterval`     | Scale      | TIER_DRIFT-LOW    |

## Red-line items

- **Pain point: cache/propagation bugs.** User-data caching + mutation-propagation is the top client-state failure mode (Gustify, Archie history shows this). Even MVP phases with `[client-state, multi-user]` tags should declare intent for Cache invalidation + Mutation propagation rows — `manual refetch` in MVP is acceptable only for solo-user local state. Flag if multi-user data + MVP invalidation coexist.
