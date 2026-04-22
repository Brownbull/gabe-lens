# Section: Multi-tenant

**Trigger tags:** `multi-tenant`, `org-scoped`

**Purpose:** Tenant isolation, RBAC, audit. Applies to phases where one code path serves multiple orgs/workspaces/customers.

## Dimensions (4)

| Dimension            | MVP                  | Δ(M→E) | Enterprise           | Δ(E→S) | Scale               |
|----------------------|----------------------|--------|----------------------|--------|---------------------|
| Auth/authz           | role check           | L      | per-tenant RBAC      | M      | + ABAC + policy eng |
| Row isolation        | WHERE tenant_id      | XL     | RLS policy           | M      | + schema per tenant |
| Audit logging        | none                 | L      | event log table      | M      | immutable + retain  |
| Noisy-neighbor       | shared pool          | M      | tenant rate-limit    | L      | + shard + throttle  |

## Notes

- **Auth/authz:** MVP = single role check at route entry (`user.is_admin`). Enterprise = per-tenant RBAC (roles scoped to tenant). Scale = attribute-based access control (ABAC) + policy engine (OPA, Casbin).
- **Row isolation:** XL skip MVP→Ent. App-level `WHERE tenant_id = ?` clauses are load-bearing — one missed query = tenant data leak. Enterprise = PostgreSQL RLS policies (defense in depth). Scale = schema-per-tenant or DB-per-tenant for top customers.
- **Audit logging:** Enterprise = dedicated `audit_events` table on every mutation. Scale = immutable WORM log + compliance-grade retention.
- **Noisy-neighbor:** MVP = shared pool, one tenant can starve others. Enterprise = per-tenant rate limits. Scale = shard large tenants or throttle at pool level.

## Tier-cap enforcement

- **MVP phase:** introducing RLS policies triggers escalation. RLS is Enterprise territory.
- **Enterprise phase:** schema-per-tenant scaffolding triggers Scale escalation.

## Known drift signals

| Pattern                                     | Tier floor | Finding severity  |
|---------------------------------------------|------------|-------------------|
| `CREATE POLICY` / `ENABLE ROW LEVEL SECURITY`| Enterprise| TIER_DRIFT-HIGH   |
| OPA policy files / Casbin enforcer          | Scale      | TIER_DRIFT-HIGH   |
| Tenant-scoped connection pools              | Scale      | TIER_DRIFT-MED    |
| Audit event emitter middleware              | Enterprise | TIER_DRIFT-MED    |
| Immutable log sink (Kafka compacted, WORM)  | Scale      | TIER_DRIFT-HIGH   |

## Red-line items

- **Row isolation in MVP.** `WHERE tenant_id = ?` must be enforced by framework/ORM default, never opt-in. `/gabe-plan` should BLOCK MVP phases where row isolation is opt-in (e.g., raw SQL with no tenant scoping middleware).
