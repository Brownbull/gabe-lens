# Section: UI Kit

**Trigger tag:** `ui-kit`

**Purpose:** Atomic + molecular component inventory for mockup / UI projects. Fills the layer between design tokens and screens. Every screen references atoms/molecules, not inline HTML. Platform variance documented once per component, not per screen.

## Dimensions (4)

| Dimension            | MVP                  | Δ(M→E) | Enterprise           | Δ(E→S) | Scale               |
|----------------------|----------------------|--------|----------------------|--------|---------------------|
| Atomic inventory     | button+input+chip    | M      | + 4 more atoms       | M      | + full 14 atoms     |
| State matrix         | default+hover        | L      | + focus/disabled/err | M      | + platform variant  |
| A11y roles           | divs everywhere      | M      | semantic HTML        | L      | + ARIA + focus trap |
| Platform variance    | web only             | M      | + mobile-web (PWA)   | M      | + native mobile     |

## Notes

- **Atomic inventory:** MVP = button + input + chip (the 3 most-reused atoms). Enterprise = + pill + badge + avatar + skeleton (7 total). Scale = full atom set: button variants (primary/secondary/ghost/destructive/icon), input variants (text/password/email/number/search), pill, badge, avatar, chip, skeleton, progress (linear/circular), spinner — ~14 atoms.
- **State matrix:** MVP = default + hover. Enterprise = + focus (visible ring, AA floor) + disabled + loading + error. Scale = + per-platform variance (iOS press scale vs Android ripple, desktop hover vs touch).
- **A11y roles:** MVP = divs + CSS classes. Enterprise = semantic HTML (`<button>` not `<div onClick>`, `<label>` not `placeholder` for fields, proper heading hierarchy). Scale = + ARIA roles on icon-only buttons, focus trap in modals, `role="tablist"` on state-tabs, full keyboard nav.
- **Platform variance:** MVP = one platform (desktop web). Enterprise = + mobile-web PWA (FAB, bottom nav, safe-area-inset). Scale = + native mobile notes per atom (haptics, biometrics affordance, platform-specific gestures documented once in component file).

## Tier-cap enforcement

- **MVP phase:** focus ring / ARIA / keyboard nav triggers Enterprise escalation.
- **MVP phase:** bottom-nav FAB / safe-area-inset triggers Enterprise escalation (mobile surface).
- **Enterprise phase:** native-mobile platform-divergence notes per atom trigger Scale escalation.

## Known drift signals

| Pattern                                        | Tier floor | Finding severity |
|------------------------------------------------|------------|------------------|
| `<div onclick=...>` for buttons                | MVP        | TIER_DRIFT-LOW   |
| `<button>` with `:focus-visible` ring          | Enterprise | TIER_DRIFT-LOW   |
| `role="tablist"` / `aria-selected`             | Enterprise | TIER_DRIFT-MED   |
| Component used inline instead of included      | Enterprise | TIER_DRIFT-MED   |
| Platform-note block per atom file              | Scale      | TIER_DRIFT-LOW   |
| Haptics / biometrics affordance documented     | Scale      | TIER_DRIFT-LOW   |

## Red-line items

- **Atom reuse.** Once Enterprise, screens MUST include atoms via `<include>` or documented snippet path, not by copy-pasting HTML. Copy-paste = component drift = re-auditing cost at Scale. State-tabs component (promoted from `gastify-single-scan-states.html` pattern) is the canonical reference — any multi-state screen MUST use it, not stack phone frames.
