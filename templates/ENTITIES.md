# Entities

<!-- Project-level principal entities — the nouns this app traffics in. -->
<!-- Created at /gabe-init time for project_type=mockup|hybrid projects. -->
<!-- Consumed by /gabe-mockup M4 to populate INDEX.md §4 CRUD×entity matrix. -->
<!-- Consumed by code plans (backend data models, API resources, migrations). -->

**Project:** [name]
**Last updated:** [YYYY-MM-DD]

---

## Entities

<!-- Add one row per principal entity. Keep flat — sub-entities (line items, tags, etc.) belong as fields on the parent or as their own row when they stand alone. -->

| Entity | Description | Related REQs | Screens (C/R/U/D) populated in INDEX.md §4 |
|--------|-------------|--------------|---------------------------------------------|
| [Entity A] | One-line description of what this entity is | REQ-N, REQ-M | filled by /gabe-mockup M4 |
| [Entity B] | ... | REQ-N | filled by /gabe-mockup M4 |

---

## Field hints (optional)

<!-- Rough field shape per entity — feeds HANDOFF.json components data-shape. Not a schema, just a hint. -->

### [Entity A]

- `id` — UUID
- `created_at` — ISO 8601
- `updated_at` — ISO 8601
- `[field]` — [type] [purpose]

### [Entity B]

- `id` — UUID
- ...

---

## Lifecycle invariants

<!-- Business rules that constrain CRUD transitions. Honored by both mockups (state machines visible in screens) and code (model/service layer). -->

- [Entity A]: cannot be deleted once [condition]. Screen: [screen-name] shows disabled Delete button when [condition] holds.
- [Entity B]: immutable after [event]. Editor screen surfaces read-only after [event].

---

## Relationships

<!-- Rough ER — one line per relation. Full ER lives in architecture docs. Here just enough context for CRUD matrix authoring. -->

- [Entity A] has many [Entity B]
- [Entity A] belongs to [User]
