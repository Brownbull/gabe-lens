# P5 — god-class-growth

## Evidence source

Gastify `docs/rebuild/LESSONS.md` §1.3 → rule R3. BoletApp `TransactionEditorViewInternal.tsx` grew to 1128 LOC (threshold 800); `src/App.tsx` accumulated 13 fix commits becoming the god-orchestrator. `useScanStore.ts` was 946 LOC before a split unblocked edits. Enforcement was 800-LOC hook only; nothing triggered splitting at 400–500 early.

## Red-line questions

- Is there a pre-commit hard block on file size (commonly 800 LOC)?
- Is there a CI warning at a lower threshold (e.g. 500 LOC) that requires justification in PR?
- Does the project require orchestration logic to live in a dedicated `orchestration/` directory rather than accumulating in `App.tsx` / `main.ts`?

## Detection — doc pass

- `.kdbp/DECISIONS.md`: ADR declaring file-size policy.
- `.git/hooks/pre-commit` / `.husky/pre-commit`: check for LOC-limit enforcement.
- `.github/workflows/*.yml`: CI size-check job present?
- `.kdbp/STRUCTURE.md`: orchestration layer declared separately from feature layer?

## Detection — code pass

- `find . -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.py" -o -name "*.js" -o -name "*.jsx" \) -not -path "*/node_modules/*" -not -path "*/dist/*" | xargs wc -l | sort -rn | head -20` — top 20 files by LOC.
- Flag any file > 800 LOC as CRITICAL, 500–800 as HIGH, 300–500 with churn as MEDIUM.
- Cross-reference with git churn: `git log --follow --format="%h" --numstat -- <file> | awk 'NF==3 {c++} END {print c}'` — commits touching this file.
- Churn × size: a large file with many commits is a god-orchestrator signal.
- Look for `App.tsx` / `main.ts` / `index.ts` root orchestrators over 300 LOC.

## Detection — commit pass

- `/refactor.*split|split.*up/i`
- `/extract component|extract hook/i`
- `/reduce.*loc|shrink.*file/i`
- Multiple fix commits on the same file: `git log --format="%s" -- <path> | grep -c "^fix" `

## Tier impact

- MVP: surfaces for any file > 800 LOC.
- Enterprise: plus any file > 500 LOC with > 10 commits in last 90 days.
- Scale: plus any file > 300 LOC whose churn-hotspot rank is top-5.

## Severity default

HIGH for > 800 LOC. MEDIUM for 500–800. LOW (but surfaced with `--full`) for 300–500 with churn.

## ADR stub template

**Decision:** File-size enforcement: 300 LOC soft signal (split candidate), 500 LOC CI warning (justification required in PR), 800 LOC pre-commit hard block.
**Rationale:** Gastify LESSONS R3. Enforcement-at-800-only let files accumulate through 400-500 (the productive "just one more feature" window) without splitting signals. 500 warning + 800 block catches drift early.
**Alternatives considered:**
1. 800 block only — rejected; proved insufficient in BoletApp.
2. Cyclomatic complexity instead of LOC — rejected; LOC is simpler, faster, and correlates well in practice.

## Open Question template

**Question:** What's the enforced file-size policy (soft warning / CI warning / hard block)? Where does orchestration code live?

## Rule template

**Rule:** Pre-commit hook blocks any file > 800 LOC. CI warns at 500 LOC with justification required in PR description. Orchestration lives in a dedicated module (e.g. `orchestration/` or `wiring/`); `App.tsx` / `main.ts` stays a thin router + provider mount.
**Detection:** pre-commit script (`loc-check.sh`), CI step running the same check, dep-cruiser / architecture rule forbidding orchestration code in root entry files.
