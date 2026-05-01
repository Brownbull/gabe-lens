# P1 — dual-state-machines

## Evidence source

Gastify `docs/rebuild/LESSONS.md` §1.1 → rule R1. BoletApp `useScanOverlayState.ts` (~240 LOC) coexisted with Zustand slices tracking the same `phase`; gallery-dismiss bug left Zustand in "scan active" while local React state was reset, blocking subsequent `setImages`.

## Red-line questions

- For each piece of state that appears in ≥2 stores/hooks/refs: is ONE the source of truth, with others derived via selector?
- Is there a single place where the invariant "X is active" is written, or can multiple handlers mutate it independently?
- When a feature has both local React state and global store state tracking the same concept, is the local state strictly a UI-only derivation?

## Detection — doc pass

- `.kdbp/DECISIONS.md`: look for ADRs declaring a state-ownership model (e.g. "Zustand is source of truth for scan phase"). Absence = implicit.
- `.kdbp/ROADMAP.md`: Why-paragraphs mentioning "sync local with store" / "keep in sync" → smell.
- `.kdbp/SCOPE.md §14`: open questions about state ownership.
- Gastify-shape projects: check `docs/rebuild/LESSONS.md` or `RULES.md` for an existing "one concept → one store" rule.

## Detection — code pass

- Grep `create<.*Store>` and `useState<.*Phase|Status|Active|State>` — if the same noun appears in both, flag.
- Grep `const \[.*, set.*\] = useState` followed by imports of a store hook that exposes the same field name → likely dual.
- AST (if available): find components that call BOTH `useStore((s) => s.X)` AND `useState<typeof X>`.
- React-specific: any `useEffect` that syncs local state *from* store state (or vice versa) is a smell — derivation via selector is preferred.

## Detection — commit pass

- `/sync.*store|store.*sync/i`
- `/mirror.*state|state.*mirror/i`
- `/keep .* in sync/i`
- `/reset local state/i` (often a band-aid for dual-source drift)

## Tier impact

- MVP: surfaces if dual-state drift has caused a user-visible bug or blocks a handler.
- Enterprise: surfaces for any confirmed dual-source pair (even without a known bug).
- Scale: surfaces for any component that mixes local + global state on overlapping field names.

## Severity default

HIGH (elevate to CRITICAL if rule R1 or equivalent already exists in RULES.md / LESSONS.md and this code violates it).

## ADR stub template

**Decision:** State for `<concept>` is owned by `<store | hook | context>`. Other representations are computed via selector / `useMemo` — never stored separately.
**Rationale:** Dual state machines drift under interactions the original design did not anticipate (see Gastify LESSONS §1.1). One source of truth is cheaper than every sync effect you'd otherwise need.
**Alternatives considered:**
1. Manual sync via `useEffect` — rejected; proved unreliable in BoletApp.
2. Event-driven replication — rejected; adds ceremony for zero gain over selectors.

## Open Question template

**Question:** Which store / hook owns the authoritative representation of `<concept>`, and which components derive from it via selector?

## Rule template

**Rule:** One concept → one store. If a visibility / status / phase field is stored in both a local React state and a global store, flag it. Derivations must use selectors, not `useEffect`-backed mirrors.
**Detection:** grep dual state field names; CI rule to fail PRs where a component imports a store hook AND declares `useState` for the same noun.
