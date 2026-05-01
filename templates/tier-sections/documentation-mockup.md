# Section: Mockup Documentation

**Trigger tag:** `mockup-docs`

**Purpose:** Handoff-artifact quality for mockup projects. Governs what downstream engineers (or the next Claude session implementing the backend) receive — HANDOFF schema fidelity, per-screen specs, component library completeness, a11y audit trail.

## Dimensions (4)

| Dimension            | MVP                  | Δ(M→E) | Enterprise           | Δ(E→S) | Scale               |
|----------------------|----------------------|--------|----------------------|--------|---------------------|
| HANDOFF schema       | md prose             | L      | + JSON schema        | M      | + machine-validated |
| SCREEN-SPECS depth   | none                 | L      | + per-screen spec    | M      | + data + states     |
| Component library    | inventory only       | M      | + state matrix       | M      | + variance tracker  |
| A11y audit           | none                 | M      | semantic HTML check  | M      | + WCAG AA contrast  |

## Notes

- **HANDOFF schema:** MVP = free-form markdown prose. Enterprise = + `HANDOFF.json` against documented schema (tokens, type, spacing, motion, components). Scale = + schema-validated at emit (Ajv / jsonschema check passes), diff-detectable across releases.
- **SCREEN-SPECS depth:** MVP = no per-screen spec, just file names. Enterprise = + `SCREEN-SPECS.md` with per-screen section (REQ coverage, components used, states documented). Scale = + data-shape stubs (what payload renders this), explicit state enumeration (idle / loading / error / empty / populated).
- **Component library:** MVP = `COMPONENT-LIBRARY.md` inventory (component name + location). Enterprise = + state matrix per component (all states documented). Scale = + platform-variance tracker (desktop vs mobile-web vs native-mobile notes per component).
- **A11y audit:** MVP = none. Enterprise = semantic-HTML check pass (labels, headings, buttons). Scale = + WCAG AA contrast ratios verified per token pairing, focus-ring visibility confirmed, screen-reader walkthrough recorded.

## Tier-cap enforcement

- **MVP phase:** JSON HANDOFF schema or per-screen spec file triggers Enterprise escalation.
- **MVP phase:** WCAG contrast ratio table or SR walkthrough triggers Scale escalation.
- **Enterprise phase:** schema validator integration or variance tracker triggers Scale escalation.

## Known drift signals

| Pattern                                        | Tier floor | Finding severity |
|------------------------------------------------|------------|------------------|
| `HANDOFF.md` present, `HANDOFF.json` absent    | Enterprise | TIER_DRIFT-LOW   |
| `SCREEN-SPECS.md` with per-screen breakdown    | Enterprise | TIER_DRIFT-LOW   |
| JSON schema validator in CI or pre-commit      | Scale      | TIER_DRIFT-MED   |
| WCAG contrast table in docs                    | Scale      | TIER_DRIFT-MED   |
| Platform-variance column in COMPONENT-LIBRARY  | Scale      | TIER_DRIFT-LOW   |
| `role=` / `aria-*` coverage >= 80% of atoms    | Enterprise | TIER_DRIFT-LOW   |

## Red-line items

- **HANDOFF schema source.** Schema lives at `templates/mockup/HANDOFF.schema.json` (Apache-2.0 derivative of pbakaus/impeccable `DESIGN.json` v2 — attribution required in skill playbook). Every mockup project's `docs/mockups/HANDOFF.json` is validated against it at P13. Scale projects auto-validate on every commit touching tokens.css.
