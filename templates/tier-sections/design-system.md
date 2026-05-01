# Section: Design System

**Trigger tag:** `design-system`

**Purpose:** Design-token discipline for mockup / UI projects — color/type/spacing/motion foundations that every atom, molecule, and screen downstream consumes. Ensures multi-theme runtime parity + no per-screen token duplication.

## Dimensions (4)

| Dimension            | MVP                  | Δ(M→E) | Enterprise           | Δ(E→S) | Scale               |
|----------------------|----------------------|--------|----------------------|--------|---------------------|
| Tokens               | 1 theme light        | M      | + dark mode          | L      | + runtime switcher  |
| Type scale           | 1 font, 4 sizes      | M      | + tabular nums       | M      | + clamp() fluid     |
| Spacing              | 4 values             | S      | + density scale      | M      | + runtime density   |
| Motion               | instant              | M      | + ease + reduced-m   | M      | + orchestrated      |

## Notes

- **Tokens:** MVP = one theme, light mode only, hardcoded in `:root`. Enterprise = + dark mode via `[data-mode]` selector, token parity enforced across both. Scale = multi-theme runtime (Tweaks panel) — themes live side-by-side, user picks at runtime, `[data-theme][data-mode]` switchable without rebuild. See `templates/mockup/tokens.css` for canonical token matrix.
- **Type scale:** MVP = one family, ~4 sizes (base / sm / lg / xl). Enterprise = + `font-variant-numeric: tabular-nums` for amounts, fixed weight set. Scale = `clamp()` fluid sizing on headings, per-theme font family swap at runtime.
- **Spacing:** MVP = `--s-2/4/6/8` (4 integer multiples of 4px or 8px). Enterprise = + `--s-1/10/12` + density scale (compact / regular / comfy → multiplier). Scale = runtime density switch via `[data-density]` on body.
- **Motion:** MVP = `transition: none` or instant. Enterprise = `--ease-out` + `prefers-reduced-motion` honored, 2-3 duration tokens. Scale = per-theme easing (bouncy / snappy / gentle), orchestrated entrances with stagger.

## Tier-cap enforcement

- **MVP phase:** multi-theme runtime switcher (Tweaks panel) or dark-mode selector triggers escalation prompt.
- **MVP phase:** density / font-family runtime switcher triggers Scale escalation.
- **Enterprise phase:** `clamp()` fluid sizing + per-theme family swap triggers Scale escalation.

## Known drift signals

| Pattern                                        | Tier floor | Finding severity |
|------------------------------------------------|------------|------------------|
| Hex/RGB literals in screen HTML (not vars)     | MVP        | TIER_DRIFT-LOW   |
| `[data-theme]` attribute + `[data-mode]`       | Enterprise | TIER_DRIFT-LOW   |
| Tokens duplicated across 3+ screens            | Enterprise | TIER_DRIFT-MED   |
| Runtime theme switcher JS / Tweaks panel       | Scale      | TIER_DRIFT-MED   |
| `clamp()` on headings + fluid type             | Scale      | TIER_DRIFT-LOW   |
| `prefers-reduced-motion` query                 | Enterprise | TIER_DRIFT-LOW   |

## Red-line items

- **Token source-of-truth.** Once Enterprise, tokens MUST live in one shared `tokens.css` file loaded by every screen. Per-screen `:root` duplication is a Scale-level drift — refactor immediately. `/gabe-commit` CHECK 7 Layer 4 surfaces the violation when an INDEX-governed project edits screens without touching tokens.css.
