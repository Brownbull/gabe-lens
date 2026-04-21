# Gabe Scope v1 — Dogfood Regression Checklist

**Purpose:** 15-check regression that verifies `/gabe-scope` + auxiliaries behave per spec when actually run against a real project. Runs at P7 (ship gate) and after any semantic change to the command family. Based on pattern from `gabe-teach-v2-dogfood.md`.

**Dogfood target:** `/home/khujta/projects/apps/ai-app/` — dry-run mode (backup `.kdbp/` first). Also usable: synthetic "bookmark manager" scenario for deterministic regression (see `templates/SCOPE.example.md` + `templates/ROADMAP.example.md`).

**Pass bar:** ≥13 of 15 checks pass to ship v1. Failures documented with remediation plan; shipping with known failures requires an entry in `docs/gabe-scope-v1-known-issues.md` (to be created on first failure).

---

## Setup

```bash
# Backup existing .kdbp/ (ai-app already has Phase 1 scoped via BUILD-GUIDE-V2)
mv /home/khujta/projects/apps/ai-app/.kdbp /home/khujta/projects/apps/ai-app/.kdbp.backup-{ts}

cd /home/khujta/projects/apps/ai-app
/gabe-scope
# ...run through 8 steps with scripted answers for determinism where possible
```

---

## Checks

### C01 — Bare invocation on empty .kdbp/ reaches Step 0.5

**Given:** fresh `.kdbp/` (no SCOPE.md, no session.json).
**When:** `/gabe-scope` run with no args.
**Expect:** Step 0 re-invocation returns "no prior scope"; command proceeds directly to Step 0.5 (Reference Frame Setup).

**Pass criteria:** auto-suggest scan output visible within first 10 lines. No error.

---

### C02 — Auto-suggest scan finds ≥2 candidates in seeded project

**Given:** dogfood target has existing refs (`docs/`, `~/.claude/rules/`, etc.).
**When:** Step 0.5 auto-suggest runs.
**Expect:** ≥2 candidate files listed with `# heading` previews.

**Pass criteria:** list contains at least one real file + preview text. No fabricated entries.

---

### C03 — Manual ref entry with all 4 weights × 3 load_modes

**When:** at Step 0.5, add 4 refs:
- `authoritative × full_read`
- `authoritative × index_only`
- `suggestive × summarize`
- `contextual × summarize`

**Expect:** `.kdbp/scope-references.yaml` valid against `schemas/scope-references.schema.json`; summarize-mode refs have `summary` + `summary_cached_at` fields populated.

**Pass criteria:** `./schemas/validate.py references .kdbp/scope-references.yaml` exits 0.

---

### C04 — Brainstorm triggers on idea-quality Q4 answer

**Given:** at Step 1 Q4, answer "Users happier, I think."
**Expect:** intake-quality-evaluator returns `quality: idea`; brainstorm-analyst invoked; 3 framings rendered with gains/gives_up columns; one probing question.

**Pass criteria:** Framings count = 3. Each has all 4 sub-fields. Probing question is one `?`-terminated sentence.

---

### C05 — Brainstorm hard-caps at 2 cycles; routes to Open Questions

**Given:** on vague Q4, reject all framings twice (cycle 1 reject → cycle 2 reject).
**Expect:** after cycle 2 rejection, answer written to §14 Open Questions with `[UNRESOLVED — brainstorm exit]` marker; command advances to Q5.

**Pass criteria:** `session.json.intake.brainstorm_cycles.Q4 == 2`; no third invocation attempt; Q4 appears in open_questions array with `status: brainstorm-exit`.

---

### C06 — Research width prompt + parallel fan-out works for quick/standard/deep

**When:** at Step 2, pick `standard` (4 agents).
**Expect:** 4 research files land in `.kdbp/research/{domain,pitfalls,stack,user-patterns}.md` within ~2 min; SUMMARY.md synthesizes all 4.

**Pass criteria:** 4 files exist + SUMMARY.md references each. Time under 5 min wallclock.

---

### C07 — Authoritative-ref conflict at Step 5 surfaces 3-option prompt

**Given:** seed an authoritative ref requiring Claude Haiku + PydanticAI. At Step 5, user's SC implies regex-based classification.
**Expect:** conflict-surfacing renders 3 options (accept / override / pause); on override, Change Log records the override rationale.

**Pass criteria:** prompt visible before SC accepted; Change Log row appears with `override` type on selection.

---

### C08 — Step 7.1 coverage block fires if SC has no REQ

**Given:** at Step 7.1, req-decomposer returns a set where one SC has no coverage.
**Expect:** 4-option prompt (regenerate / add manually / --force / back) appears. No advance without resolution.

**Pass criteria:** `session.json.coverage_status.scs_without_reqs` non-empty; command refuses Checkpoint 7.1 approval until resolved or --force.

---

### C09 — Step 7.4 re-runs coverage on user edit

**Given:** after populate mode, user moves REQ-02 from Phase 2 to Phase 3 via in-file edit.
**Expect:** coverage validator re-runs on checkpoint attempt; if move creates orphan or duplicate, surface error.

**Pass criteria:** coverage matrix re-rendered after edit. `reqs_duplicated` and `reqs_uncovered` both empty before approve can succeed.

---

### C10 — Step 8 archives research, writes tombstone, offers git-commit

**When:** full end-to-end run completes.
**Expect:**
- `.kdbp/research/` moved to `.kdbp/research/archive/{ts}/`
- `.kdbp/scope-session.json` moved to `.kdbp/archive/tombstones/scope-session-{ts}.json`
- `.kdbp/CHANGES.jsonl` has a `scope_init` row
- `.kdbp/KNOWLEDGE.md` gets (or updates) Root artifacts section
- Git-commit prompt appears with suggested message

**Pass criteria:** all 5 side-effects verifiable via `ls` + `grep`. No auto-push. No amend of prior commits.

---

### C11 — `/gabe-scope-change` with Primary-User change routes to pivot

**Given:** finalized SCOPE.md with primary_user = "solo knowledge workers". User runs `/gabe-scope-change "let's focus on enterprise teams instead"`.
**Expect:** classifier returns `{classification: pivot, trigger_rule: primary_user, confidence: high}`; user prompted with pivot-suggested routing.

**Pass criteria:** classifier trigger_rule == primary_user. Suggested next command == `/gabe-scope-pivot`. CHANGES.jsonl records the classification decision.

---

### C12 — `/gabe-scope-change` with new-REQ routes to addition

**Given:** finalized SCOPE.md. User runs `/gabe-scope-change "add REQ for export-to-markdown, existing SCs still hold"`.
**Expect:** classifier returns `{classification: addition, trigger_rule: none}`; routed to `/gabe-scope-addition`.

**Pass criteria:** classifier trigger_rule == none. No pivot archive. SCOPE.md version unchanged; ROADMAP.md roadmap_version bumps.

---

### C13 — Session pause at Step 3, resume at Step 4 with markers visible

**Given:** pause command mid-Step 3 via `pause` keyword. Close shell. Re-open. Run `/gabe-scope`.
**Expect:** Step 0 re-invocation detects session.json; prompts to resume; on resume, `[PENDING APPROVAL — step-3]` markers visible in SCOPE.md draft.

**Pass criteria:** session resumes at Step 3 exactly (session.json.current_step). Markers appear in editor view of SCOPE.md.

---

### C14 — `--force` escape works on coverage block

**Given:** at Step 7.1, force-skip an incomplete coverage set.
**Expect:** command accepts with `session.json.coverage_status.force_override: true`; finalize records `finalize_forced_at: {ts}` in session.json + CHANGES.jsonl row.

**Pass criteria:** both fields written. `--force` logged in the final commit message if user opts in.

---

### C15 — Start-over requires typed confirmation + archives to tombstone

**Given:** finalized SCOPE.md exists. User runs `/gabe-scope --start-over`.
**Expect:** typed-confirm prompt ("type `start over` to confirm"). On confirm, SCOPE.md + ROADMAP.md + scope-references.yaml move to `.kdbp/archive/tombstones/{ts}/`. Nothing deleted.

**Pass criteria:** typed string match enforced (any other response aborts). Archive directory exists post-run with all 3 files inside.

---

## Running the regression

Each check is manual (requires human judgement on outputs). Record pass/fail in a local runbook:

```bash
# Template for a run log
cat > dogfood-run-$(date +%Y%m%d).md <<EOF
# Dogfood Run — $(date +%Y-%m-%d)

Target: /home/khujta/projects/apps/ai-app/
Duration: {hh:mm}
Command version: v1.0
Prompts version: check prompts/README.md

## Results

| Check | Pass/Fail | Notes |
|---|---|---|
| C01 | | |
| C02 | | |
...
EOF
```

---

## Known limitations (v1)

- **Classifier 23-scenario gate** (fixtures 6–23 from SCENARIOS.md) runs manually here at C11/C12 level only. Full suite validation deferred until command is exercised on ≥3 real projects and misclassifications (if any) fed back into prompt v3.
- **Integration checks (C11–C12)** test routing but don't exhaustively verify every trigger rule — would require 9 scenarios × real LLM runs per release. Reserved for release gates only.
- **Cross-command scope-drift checks** (gabe-align integration from P7) not tested here — separate regression in `docs/gabe-align-scope-integration.md` (future).

---

## Ship criteria

- **≥13/15 checks pass** against fresh ai-app run
- **0 CRITICAL deviations** in results (e.g., data loss, silent corruption, bypass of typed-confirm)
- **HIGH deviations documented** in known-issues doc with remediation plan
- **MEDIUM/LOW** acceptable for v1.0 ship; track in follow-up issues

Once met, bump command version from `v1.0` to `v1.0-GA` in commands/gabe-scope.md frontmatter and add release row to CHANGELOG.
