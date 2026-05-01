# [Project] Mockup Index

<!-- Seeded during /gabe-mockup M4 (flows + INDEX + CRUD×entity). Living doc — P5-P12 update §3/§4/§5/§6. -->
<!-- Consumed by /gabe-commit CHECK 7 Layer 4 (freshness check). -->

**Project:** [name]
**Last updated:** [YYYY-MM-DD]
**Active plan:** `../../.kdbp/PLAN.md`
**Entities source:** `../../.kdbp/ENTITIES.md`

---

## 1. Decisions log

<!-- Mirrors .kdbp/DECISIONS.md D-entries that affect mockup surface. -->
<!-- One row per decision. Linked back to D-id anchor in DECISIONS.md. -->

| # | Decision | Date | Rationale | Affects |
|---|----------|------|-----------|---------|
| D1 | [e.g., multi-theme runtime vs single theme] | YYYY-MM-DD | [why] | P1, tokens.css |
| D2 | [e.g., 2 platforms vs 3] | YYYY-MM-DD | [why] | all screen phases |

---

## 2. Workflows

<!-- Flow catalog. Seeded from PLAN.md P4. Each row links to flows/<N>-<name>.html walkthrough. -->

| Flow | REQ coverage | Primary screens | Entry point | Desktop | Mobile |
|------|--------------|-----------------|-------------|---------|--------|
| F1 — [flow name] | REQ-N | screen-a, screen-b | [dashboard] | flows/f01-desktop.html | flows/f01-mobile.html |
| F2 — [flow name] | REQ-N | ... | ... | ... | ... |

---

## 3. Screens — by section (desktop + mobile)

<!-- One section per PLAN phase cluster (P5 auth, P6 capture, P7 batch, P8 data-view, P9 analytics, P10 groups, P11 settings, P12 edge-states). -->

### 3.1 Auth + onboarding (P5)

| Screen | Desktop file | Mobile file | Status | REQ | Primary entity |
|--------|--------------|-------------|--------|-----|----------------|
| Login | screens/login-desktop.html | screens/login-mobile.html | LIVE | REQ-16 | User |
| Register | — | — | PLANNED | REQ-16 | User |
| Jurisdiction Consent | — | — | PLANNED | REQ-20 | Consent |

### 3.2 Core capture (P6)

| Screen | Desktop file | Mobile file | Status | REQ | Primary entity |
|--------|--------------|-------------|--------|-----|----------------|
| Dashboard | screens/dashboard-desktop.html | screens/dashboard-mobile.html | LIVE | REQ-05, REQ-06 | Transaction |
| ... | | | | | |

### 3.N [Section name]

| Screen | Desktop file | Mobile file | Status | REQ | Primary entity |
|--------|--------------|-------------|--------|-----|----------------|
| ... | | | | | |

---

## 4. CRUD × entity matrix

<!-- Source: .kdbp/ENTITIES.md entity list. Each entity row: 4 columns (Create/Read/Update/Delete). -->
<!-- Populated progressively through P5-P12. Blank cells mean coverage gap. -->

| Entity | Created by | Viewed on | Modified by | Deleted by |
|--------|------------|-----------|-------------|------------|
| [Entity A] | screen-create, screen-quick | dashboard, history | screen-editor | screen-editor (delete confirm) |
| [Entity B] | — | dashboard | — | — |

---

## 5. Component usage × screen

<!-- Keeps components from drifting. Updated as M5-M12 land screens. -->

| Component | Declared in | Used on |
|-----------|-------------|---------|
| state-tabs | molecules/state-tabs.html | single-scan-states, login, consent |
| transaction-card | molecules/card-transaction.html | dashboard, history, insights |
| toast | molecules/toast.html | everywhere via tweaks.js |

---

## 6. Coverage gaps

<!-- Initial baseline synced from AUDIT.md if it existed at project start. Shrinks as screens land. -->
<!-- Each PR touching docs/mockups/** should update this section when closing a gap. -->
<!-- Scale tier: blocking at /gabe-commit when left stale. -->

### Gap priority stack

| Priority | Area | Scope | Status |
|----------|------|-------|--------|
| P0 | [e.g., Desktop variants for all 29 screens] | REQ-23 | 0 of 29 done |
| P1 | [area] | [REQs] | [status] |

### Per-REQ coverage

| REQ | Fully covered | Partial | Missing | Not user-facing |
|-----|---------------|---------|---------|-----------------|
| REQ-01 | ✅ | | | |
| REQ-02 | | | | ✅ (backend) |
| REQ-03 | | ⚠ (needs verify) | | |

---

## 7. Handoff index

<!-- Populated at M13. Links to machine-readable contract + audit trail. -->

- **HANDOFF.json** — machine-readable design contract ([schema](../../../../gabe_lens/templates/mockup/HANDOFF.schema.json))
- **SCREEN-SPECS.md** — per-screen breakdown (REQ, components, states, data shape)
- **COMPONENT-LIBRARY.md** — molecules inventory + state matrix + platform variance
- **AUDIT.md** — retrospective consistency/continuity/coverage audit (pre-INDEX, may be folded into §6 above)
- **a11y WCAG AA pass table** — contrast ratios per token pairing
