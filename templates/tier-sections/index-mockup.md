# Section: Mockup Index

**Trigger tag:** `mockup-index`

**Purpose:** Project-level INDEX.md governance — decisions log, workflow catalog, screens-by-section table (desktop+mobile split), CRUD×entity matrix, component usage tracker, coverage gaps. Single source of navigation truth for mockup projects. Seeded at P4, updated through P5-P12, audited at P13.

## Dimensions (4)

| Dimension            | MVP                  | Δ(M→E) | Enterprise           | Δ(E→S) | Scale               |
|----------------------|----------------------|--------|----------------------|--------|---------------------|
| Decisions log        | seeded once          | M      | + dated, D-id links  | M      | + auto-sync         |
| Workflows            | list F1..Fn          | M      | + REQ mapping        | M      | + flow diagrams     |
| Screens by section   | desktop OR mobile    | M      | + desktop+mobile     | M      | + status+REQ+comp   |
| CRUD x entity        | blank skeleton       | L      | + C/R/U/D populated  | M      | + comp usage        |

## Notes

- **Decisions log:** MVP = one-time seed from DECISIONS.md at P4. Enterprise = + dated entries, each linked back to a D-id anchor in DECISIONS.md. Scale = + auto-sync hook — new decision in DECISIONS.md appears in INDEX.md next commit (via `/gabe-commit` CHECK 7 Layer 4 reminder).
- **Workflows:** MVP = flat list of flow names (F1..Fn). Enterprise = + REQ mapping per flow (which REQ each flow satisfies). Scale = + inline flow diagrams (mermaid sequenceDiagram), linked to HTML walkthroughs in `flows/`.
- **Screens by section:** MVP = single column (pick desktop OR mobile, document one). Enterprise = + desktop AND mobile columns side-by-side per screen row. Scale = + status column (LIVE/IN-DEV/PLANNED/FUTURE) + REQ coverage + component list used.
- **CRUD × entity:** MVP = blank matrix skeleton from ENTITIES.md (entity list down, C/R/U/D columns blank). Enterprise = + populated: for each entity, list the screens that create, read/view, update, delete it. Scale = + component-usage layer (same matrix with "uses which molecule" column so molecule drift is visible).

## Tier-cap enforcement

- **MVP phase:** desktop+mobile split columns or dated decision entries trigger Enterprise escalation.
- **MVP phase:** populated CRUD cells (non-blank) trigger Enterprise.
- **Enterprise phase:** auto-sync hook, flow diagrams, or component-usage tracker triggers Scale.

## Known drift signals

| Pattern                                        | Tier floor | Finding severity |
|------------------------------------------------|------------|------------------|
| INDEX.md has decisions but not linked to D-ids | Enterprise | TIER_DRIFT-LOW   |
| Screens table has one platform only            | MVP        | TIER_DRIFT-LOW   |
| CRUD matrix cells all "—" after P5 ships       | Enterprise | TIER_DRIFT-MED   |
| Mermaid sequenceDiagram in Workflows section   | Scale      | TIER_DRIFT-LOW   |
| Component-usage column in screens table        | Scale      | TIER_DRIFT-LOW   |
| `last-synced: <date>` header in INDEX.md       | Scale      | TIER_DRIFT-LOW   |

## Red-line items

- **Freshness gate.** INDEX.md must be touched in every PR that adds or modifies a screen. `/gabe-commit` CHECK 7 Layer 4 surfaces low-severity finding when `docs/mockups/**` diff excludes `INDEX.md`. Not blocking, but visible. Scale projects promote this to blocking.
