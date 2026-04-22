# Section: Data

**Trigger tags:** `data-migration`, `persistence`

**Purpose:** Server-side persistence + schema evolution. Applies to phases that touch database schema, migrations, backups, or indexing.

## Dimensions (4)

| Dimension            | MVP                  | Δ(M→E) | Enterprise           | Δ(E→S) | Scale               |
|----------------------|----------------------|--------|----------------------|--------|---------------------|
| Schema stability     | adhoc change         | L      | migration file       | M      | + rollback + audit  |
| Migration safety     | run on deploy        | L      | pre-run + dry        | M      | + blue-green swap   |
| Backup/restore       | none                 | XL     | daily snapshot       | M      | + PITR + tested     |
| Indexing             | as query bites       | M      | planned at design    | M      | + monitored + tuned |

## Notes

- **Schema stability:** "adhoc change" = `ALTER TABLE` in a script or console. MVP acceptable only for dev/prototype. Enterprise = versioned migration files. Scale = + rollback migrations tested on snapshot + audit trail of schema changes.
- **Migration safety:** MVP runs the migration as part of deploy script — outage if migration fails mid-flight. Enterprise = pre-deploy dry-run on snapshot. Scale = blue-green schema swap (new schema in parallel, cutover atomic).
- **Backup/restore:** XL skip MVP→Ent. `none` is existential. Even prototype apps touching real data need daily snapshots. Scale = Point-in-Time Recovery + quarterly restore drills.
- **Indexing:** MVP = add indexes when queries visibly slow. Enterprise = plan indexes at schema design. Scale = monitor query plans, tune iteratively.

## Tier-cap enforcement

- **MVP phase:** creating complex indexes (GIN, partial, covering) triggers escalation prompt. Ask: "Is Enterprise-tier indexing really needed for this phase?"
- **Enterprise phase:** PITR setup / restore test harness triggers Scale escalation.

## Known drift signals

| Pattern                                     | Tier floor | Finding severity  |
|---------------------------------------------|------------|-------------------|
| `pg_cron` / scheduled maintenance jobs      | Enterprise | TIER_DRIFT-MED    |
| Blue-green migration scaffold               | Scale      | TIER_DRIFT-HIGH   |
| PITR / WAL archiving config                 | Scale      | TIER_DRIFT-MED    |
| Query plan monitoring (`pg_stat_statements` active consumer) | Scale | TIER_DRIFT-MED |
| Multi-region replication                    | Scale      | TIER_DRIFT-HIGH   |

## Red-line items (never MVP-skip regardless of tier)

- **Backups.** Even MVP ships with daily snapshot. Backup/restore row's MVP cell reads `none` only when there is genuinely no data worth preserving (in-memory cache, ephemeral queue, hackathon demo). `/gabe-plan` should flag if MVP+data-migration phase has no backup strategy declared.
