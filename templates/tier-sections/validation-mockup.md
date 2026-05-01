# Section: Mockup Validation

**Trigger tag:** `mockup-validation`

**Purpose:** Final-gate audit for mockup projects. Governs REQ×screen coverage, cross-screen consistency (no drift across 50+ screens), token parity across all themes × modes, a11y pass at WCAG AA floor.

## Dimensions (4)

| Dimension            | MVP                  | Δ(M→E) | Enterprise           | Δ(E→S) | Scale               |
|----------------------|----------------------|--------|----------------------|--------|---------------------|
| REQ x screen         | spot-check           | M      | + matrix per REQ     | M      | + living audit      |
| Cross-screen check   | manual eyeball       | L      | + token lint pass    | M      | + drift detector    |
| Token parity         | 1 theme only         | M      | + parity check M×N   | M      | + diff reporter     |
| A11y pass            | none                 | L      | + semantic + focus   | M      | + WCAG AA + SR test |

## Notes

- **REQ × screen:** MVP = spot-check (pick 3 REQs, verify they have screens). Enterprise = + matrix in `INDEX.md §4` populated for every REQ. Scale = + living audit — each PR updates the matrix, gaps surface at `/gabe-commit` Layer 4.
- **Cross-screen check:** MVP = manual eyeball (does it look consistent?). Enterprise = + `tokens.css` lint — scan screens for hex literals that should be vars, flag deviations. Scale = + drift detector — automated diff of component usage vs COMPONENT-LIBRARY.md.
- **Token parity:** MVP = one theme only, no parity to check. Enterprise = + every theme defines all canonical tokens (6-theme × 2-mode parity matrix). Scale = + diff reporter: when a new token lands in one theme, flag if others don't have it.
- **A11y pass:** MVP = none. Enterprise = + semantic HTML + visible focus rings on every interactive. Scale = + WCAG AA contrast on every token pairing + screen-reader walkthrough recorded (VoiceOver / NVDA).

## Tier-cap enforcement

- **MVP phase:** REQ×screen matrix authoring or tokens.css lint triggers Enterprise escalation.
- **MVP phase:** token parity check across multiple themes triggers Enterprise.
- **Enterprise phase:** drift detector automation or SR walkthrough triggers Scale.

## Known drift signals

| Pattern                                        | Tier floor | Finding severity |
|------------------------------------------------|------------|------------------|
| AUDIT.md or similar coverage-gap doc present   | Enterprise | TIER_DRIFT-LOW   |
| Hex/RGB literal outside tokens.css             | Enterprise | TIER_DRIFT-MED   |
| Token missing in one theme but present in 2+   | Enterprise | TIER_DRIFT-MED   |
| Automated component-drift detector in CI       | Scale      | TIER_DRIFT-MED   |
| WCAG AA contrast ratio table in HANDOFF        | Scale      | TIER_DRIFT-LOW   |
| Screen-reader walkthrough recording / notes    | Scale      | TIER_DRIFT-LOW   |

## Red-line items

- **P13 gate.** Validation phase is not optional at Enterprise or Scale. Phase row with `mockup-validation` tag + Exec ✅ but no INDEX.md §6 Coverage gaps update = blocking finding at `/gabe-commit`. AUDIT methodology from `gastify/docs/mockups/AUDIT.md` (consistency / continuity / coverage) is the reference workflow — port into skill playbook M13 recipe.
