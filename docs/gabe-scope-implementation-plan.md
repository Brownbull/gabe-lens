# /gabe-scope Implementation Plan

**Status:** Approved — ready to execute Phase 1
**Date:** 2026-04-21
**Design spec:** [gabe-scope-design.md v0.3](./gabe-scope-design.md)
**Authors:** brownbull + Claude (planner agent)

---

## 0. How to use this doc

This is the **execution plan**. The [design spec](./gabe-scope-design.md) is the *what + why*; this is the *how + when*. Read that first if you haven't.

Execution proceeds phase-by-phase. Each phase ends with a Definition of Done (DoD) checklist that gates commit + mirror. If you pause mid-phase, leave a note at the bottom of this doc.

---

## 1. Requirements Restatement (condensed)

Build the backbone authoring command family for the Gabe Lens suite: a multi-step, checkpoint-gated, Opus-heavy workflow that produces two linked artifacts per project — a stable `SCOPE.md` (premise) and a fluid `ROADMAP.md` (phase plan). The family is 4 commands: `/gabe-scope` (author v1), `/gabe-scope-change` (classifier router), `/gabe-scope-addition`, `/gabe-scope-pivot`.

**Critical non-obvious requirements:**
- Dual resume (`.kdbp/scope-session.json` + `[PENDING APPROVAL]` markers)
- 100% coverage invariant (SC → REQ → Phase)
- Conflict surfacing at Steps 5/6/7 against authoritative Reference Frame entries
- Pivot-vs-addition is Opus-reasoning with declared rules, not heuristics
- Tombstone-never-delete on all destructive ops
- Prompts are versioned; session.json records version used

**Out of scope for first implementation** (deferred to Phase 7 or later):
- `/gabe-plan` integration edits
- `/gabe-teach` SCOPE mode
- `/gabe-align` drift watchdog detail

---

## 2. Locked sequencing decisions

- **Schema → Prompts → Glue.** Templates must land before prompts, because prompts fill the template's section schema.
- **Prompts live in `/home/khujta/projects/gabe_lens/prompts/` as standalone files** during Phases 1–5 (Option A). Final ship decision (ship-to-`~/.claude/prompts/` vs. inline into command file at build time) deferred to Phase 7.
- **Two-repo sync per phase DoD**, not at the end. Mirror only after each phase passes its independent test + git commit.
- **Dogfood target:** `/home/khujta/projects/apps/ai-app/` in dry-run mode + synthetic "bookmark manager" scenario for deterministic regression.

---

## 3. Risk Register (prioritized by IMPLEMENTATION risk)

| # | Risk | Prob. | Impact | Mitigation |
|---|---|---|---|---|
| IR1 | Prompt quality regressions undetectable without scoring harness | High | 2x–3x timeline | Build harness in Phase 1; every prompt has frozen fixtures + rubric |
| IR2 | Session.json schema churn after Phase 3 | High | 1.5x timeline | Freeze schema in Phase 2; version it; prompts read via adapter |
| IR3 | Reference Frame threading bloats token budget | Medium | Medium | 3k token cap assertion in harness; test index_only + summarize from day one |
| IR4 | Step 7 coverage validation deceptively tricky | Medium | Medium | Dedicate Phase 5 to Step 7 alone; deterministic validator function |
| IR5 | Brainstorm sub-loop runaway | Medium | Low-Med | Hard 2-cycle cap in prompt AND command; log cycle count |
| IR6 | Pivot-trigger classifier false-negatives | Medium | High (users) | 20-fixture hand-labeled test suite before Phase 6 ships; ≥95% accuracy gate |
| IR7 | Two-repo sync drifts during active dev | High | Low per event, compounding | Mirror per phase DoD; checkbox gate |
| IR8 | Dogfood needs realistic greenfield | Medium | Medium | Use ai-app dry-run + synthetic "bookmark manager" |
| IR9 | Phase 7 integration edits force schema changes back to Phase 2 | Medium | Medium | Phase 2 includes 15-min review of `/gabe-plan`, `/gabe-align`, `/gabe-teach` read-needs |

---

## 4. Phases

### Phase summary table

| # | Phase | Goal | Complexity | Hours | Parallel? | Depends |
|---|---|---|---|---|---|---|
| 1 | Scaffolding + Prompt Test Harness | Harness + fixtures runnable | M | 4–6 | With P2 (partially) | — |
| 2 | Templates + Schemas | All data contracts frozen | M | 4–6 | With P1 | — |
| 3 | Prompt Authoring (7 Opus + 5 Sonnet) | Every prompt passes harness | H | 8–14 | Partial internal | P1, P2 |
| 4 | `/gabe-scope` Steps 0–6 | Command dry-runs through Step 6 | H | 6–8 | — | P2, P3 |
| 5 | Step 7 + Step 8 Finalize | End-to-end dry-run completes | H | 5–7 | — | P4 |
| 6 | Auxiliary cmds (-change, -addition, -pivot) | All 4 commands shipped | M | 5–7 | With P5 partially | P3, P4 |
| 7 | Integration + dogfood | Regression checklist passes | M | 4–6 | — | All |
| **Total** | | | **HIGH** | **36–54** | | |

---

### Phase 1 — Scaffolding + Prompt Test Harness

**Goal:** A prompt fixture runs end-to-end against a real Opus call and produces a scored pass/fail result — without any `/gabe-scope` command existing.

**Deliverables:**
- `/home/khujta/projects/gabe_lens/prompts/` — new dir
- `/home/khujta/projects/gabe_lens/prompts/README.md` — versioning convention (`vN` frontmatter; session.json records version)
- `/home/khujta/projects/gabe_lens/tests/scope-prompt-harness/` — harness
- `tests/scope-prompt-harness/run.sh` — CLI: takes prompt + fixture, calls LLM, scores against rubric
- `tests/scope-prompt-harness/fixtures/` — 3–5 synthetic scenarios (spec-user, idea-user, mixed, authoritative-conflict, empty-ref-frame)
- `tests/scope-prompt-harness/rubrics/` — one JSON rubric per prompt type (shape assertions, not exact match)

**DoD:**
- [ ] `run.sh` executes against a dummy placeholder prompt; all fixtures fail (proves harness works)
- [ ] README documents prompt-version frontmatter schema
- [ ] Rubric format documented with one worked example
- [ ] Git commit in `gabe_lens/`: `feat(gabe-scope): P1 prompt test harness`
- [ ] No mirror to refrepos yet (build-time asset)

**Note on rubrics:** Author rubric content LAST in P1, after P2 data-contracts doc lands. Harness infra is independent; rubric content isn't.

---

### Phase 2 — Templates + Schemas

**Goal:** A hand-assembled valid `SCOPE.md` + `ROADMAP.md` + `scope-references.yaml` + `scope-session.json` pass schema validation; all cross-references resolve.

**Deliverables:**
- `/home/khujta/projects/gabe_lens/templates/SCOPE.md` — §3a spec: §0 Reference Frame, frontmatter, 15 sections, coverage matrix placeholder, Change Log format
- `/home/khujta/projects/gabe_lens/templates/ROADMAP.md` — frontmatter, Phase Table (integer + decimal IDs), dependency graph placeholder, Roadmap Change Log
- `/home/khujta/projects/gabe_lens/templates/scope-references.yaml` — canonical example with 4 weights × 3 load modes
- `/home/khujta/projects/gabe_lens/schemas/scope-session.schema.json` — JSON Schema (step, sub-step, checkpoint-status, prompt versions, brainstorm-cycle counts, research-width, granularity, pending-approval markers)
- `/home/khujta/projects/gabe_lens/schemas/scope-references.schema.json` — JSON Schema for the YAML
- `/home/khujta/projects/gabe_lens/docs/scope-data-contracts.md` — authoritative doc listing every field in every artifact and which step writes it
- **15-min review (part of this phase):** Read `/gabe-plan`, `/gabe-align`, `/gabe-teach` command files; document their read-needs in `scope-data-contracts.md` to prevent Phase 7 rework

**DoD:**
- [ ] Handcrafted valid examples pass a schema validator (ajv or similar)
- [ ] One deliberately-broken example per artifact fails the validator with a useful error
- [ ] 15-min read-needs review complete and documented
- [ ] Git commit in `gabe_lens/`: `feat(gabe-scope): P2 templates + schemas + data-contracts doc`
- [ ] Mirror templates + schemas to `refrepos/setup/cherry-pick/kdbp/templates/` and `.../schemas/`
- [ ] Git commit in `refrepos/`: `feat(kdbp): mirror gabe-scope P2 templates + schemas`

---

### Phase 3 — Prompt Authoring

**Goal:** All 12 prompts (7 Opus + 5 Sonnet) pass their rubrics against Phase 1 fixtures, with token-budget assertions holding.

**Deliverables (each file has frontmatter: `version: v1`, `model: opus|sonnet`, `token_budget: N`, `rubric: path`):**

**Opus (7):**
- `prompts/intake-quality-evaluator.md` — returns `{quality: spec|idea, signals, gap_opened, gap_question}`
- `prompts/brainstorm-analyst.md` — §3.5 Mary-persona: reframe + 2–3 framings + probing question
- `prompts/success-criteria-generator.md` — goal-backward SCs from intake + research
- `prompts/non-goals-generator.md` — non-goals with "why we said no"
- `prompts/req-decomposer.md` — SC → REQ-01..N with SC-tag
- `prompts/phase-skeleton-and-populator.md` — two modes: skeleton-only (7.3) or populate (7.4)
- `prompts/scope-change-classifier.md` — pivot-vs-addition router with rationale per §2 rules

**Sonnet (5):**
- `prompts/intake-summary-assembler.md` — compresses interview into structured summary
- `prompts/users-and-non-users-drafter.md` — Sections 4–6
- `prompts/constraints-and-posture-drafter.md` — Section 9–10
- `prompts/reference-summarizer.md` — for `summarize` load-mode refs at Step 0.5
- `prompts/final-assembler.md` — Step 8 final SCOPE.md + ROADMAP.md assembly

**DoD per prompt:**
- [ ] ≥3 fixture inputs cover spec-quality, idea-quality, edge cases
- [ ] Rubric passes deterministically across 3 consecutive runs (temp=0 where supported, else ≥2/3)
- [ ] Token budget within declared cap across all fixture runs
- [ ] No hallucinated section names outside Phase 2 schema
- [ ] Negative fixture (malformed input) → controlled failure shape, no cascading error
- [ ] Classifier prompt: ≥95% correctness on 20 hand-labeled scope-change scenarios

**DoD for phase:**
- [ ] All 12 prompts ship
- [ ] 20-scenario classifier fixture suite documented in `tests/scope-prompt-harness/fixtures/classifier-scenarios.md`
- [ ] Git commit in `gabe_lens/`: `feat(gabe-scope): P3 prompt authoring (12 prompts)`
- [ ] No mirror yet (prompts are build-time until Phase 7 decision)

**Hours reality check:** Realistic range 8–14 hrs. Brainstorm-analyst and phase-skeleton prompts are the hardest (budget 3 hrs each). Intake evaluator may need 2–3 iterations.

---

### Phase 4 — `/gabe-scope` Command Spec, Steps 0–6

**Goal:** A real `/gabe-scope` invocation on a scratch project completes Steps 0, 0.5, 1, 2, 3, 4, 5, 6 with session.json checkpoints, `[PENDING APPROVAL]` markers, and Reference Frame threading.

**Deliverables:**
- `/home/khujta/projects/gabe_lens/commands/gabe-scope.md` — mirrors `gabe-teach.md` structure (~1500–2500 lines)
- Step 0 re-invocation logic (4-case matrix)
- Step 0.5 Reference Frame auto-suggest scanner (deterministic FS walk) + manual entry + summarize-pass invocation
- Step 1 interview loop with +10 follow-up cap + brainstorm sub-loop invocation (cap 2 cycles)
- Step 2 research fan-out (parallel Task agents, Sonnet) + synthesis (Opus)
- Steps 3–6 drafting + in-file `[PENDING APPROVAL]` workflow
- Conflict-surfacing logic at Steps 5 and 6
- `.kdbp/scope-session.json` writer/reader conventions

**DoD:**
- [ ] Dry-run up to Step 6 on cloned `/home/khujta/projects/apps/ai-app/` completes without errors
- [ ] session.json shape matches P2 schema
- [ ] Pending-approval markers appear in draft SCOPE.md
- [ ] Seeded authoritative-ref conflict at Step 5 surfaces 3-option prompt
- [ ] Brainstorm sub-loop fires on seeded idea-quality answer; caps at 2 cycles
- [ ] Git commit in `gabe_lens/`: `feat(gabe-scope): P4 command spec Steps 0-6`
- [ ] Mirror `commands/gabe-scope.md` to `refrepos/setup/cherry-pick/kdbp/commands/`
- [ ] Git commit in `refrepos/`: `feat(kdbp): mirror gabe-scope P4`

---

### Phase 5 — Step 7 (REQs + Roadmap) + Step 8 (Finalize)

**Goal:** A full `/gabe-scope` run from empty `.kdbp/` produces finalized `SCOPE.md` + `ROADMAP.md` + archived research, coverage matrix validating 100%, Change Log `init` entry, tombstone marker present.

**Deliverables:**
- Step 7.1 REQ decomposition + coverage check (SC has ≥1 REQ; `--force` escape)
- Step 7.2 granularity prompt (coarse/standard/fine/custom)
- Step 7.3 skeleton render + user edit loop
- Step 7.4 population + coverage check (every REQ in exactly 1 phase; re-run on edit)
- Coverage matrix generator (deterministic function, documented with pseudocode)
- Step 8 final assembly (Sonnet) with Mermaid graph generation
- Research archival, session.json tombstoning, CHANGES.jsonl writer (per Q5)
- `.kdbp/KNOWLEDGE.md` pointer update
- Git-commit prompt at finalize

**DoD:**
- [ ] Full end-to-end run on a synthetic "bookmark manager" scenario completes Step 8
- [ ] Finalized SCOPE.md passes schema validator
- [ ] Finalized ROADMAP.md passes schema validator
- [ ] Coverage matrix validates 100% in output
- [ ] Research archived to `.kdbp/research/archive/`
- [ ] Tombstone at `.kdbp/archive/tombstones/scope-session-{ts}.json`
- [ ] `--force` escape works on coverage block
- [ ] Git commit in `gabe_lens/`: `feat(gabe-scope): P5 Step 7 + Step 8 finalize`
- [ ] Mirror + commit in `refrepos/`

---

### Phase 6 — Auxiliary Commands

**Goal:** Finalized SCOPE.md receives both an addition (routed correctly) and a pivot (routed correctly, archives to vN, creates vN+1) via the classifier.

**Deliverables:**
- `commands/gabe-scope-change.md` — classifier invocation + routing + `--force-addition`/`--force-pivot`
- `commands/gabe-scope-addition.md` — SCOPE Change Log append, REQ append, ROADMAP decimal-ID phase insertion, Sonnet draft
- `commands/gabe-scope-pivot.md` — archive `SCOPE.md` → `SCOPE.vN.md` + `ROADMAP.md` → `ROADMAP.vN.md`, re-derive vN+1, Opus drafting

**DoD:**
- [ ] Classifier ≥95% on 20-fixture suite from Phase 3
- [ ] Seeded addition (new REQ) routes to `-addition` and inserts at correct decimal ID
- [ ] Seeded pivot (Primary User change) routes to `-pivot` and bumps `version:` in frontmatter
- [ ] Ref downgrade (authoritative → suggestive) classifies as pivot
- [ ] Archived files in `.kdbp/` (never deleted)
- [ ] Git commit + mirror

**Parallel with P5:** Classifier + `-addition` can start after Phase 3; `-pivot` must wait for P5 (shared finalize machinery).

---

### Phase 7 — Integration Edits + Dogfood Validation

**Goal:** Dogfood regression checklist passes on `/home/khujta/projects/apps/ai-app/`; suite-wide integration points updated.

**Deliverables:**
- `/gabe-plan` edit: read ROADMAP.md for phase + Covers-REQs, read SCOPE.md for REQ text
- `/gabe-teach` edit: add SCOPE mode alongside ARCH mode
- `/gabe-align`, `/gabe-review`, `/gabe-commit`, `/gabe-push` edits per design §6
- `docs/gabe-scope-v1-dogfood.md` — 15-check regression report (like `gabe-teach-v2-dogfood.md`)
- `install.sh` updated: include `gabe-scope`, `gabe-scope-change`, `gabe-scope-addition`, `gabe-scope-pivot` in COMMANDS_ONLY
- **Decision point:** ship prompts to `~/.claude/prompts/` (Option A) or inline them (Option B)?
- Mirror to `refrepos/setup/cherry-pick/kdbp/`

**Dogfood regression checklist (15 checks):**
1. Bare `/gabe-scope` on empty `.kdbp/` reaches Step 0.5
2. Auto-suggest Reference Frame scan finds ≥2 candidates in seeded project
3. Manual ref entry with each weight × load-mode combo works
4. Brainstorm triggers on idea-quality answer; produces 3 framings
5. Brainstorm hard-caps at 2 cycles; routes to Open Questions
6. Research fan-out width prompt works for quick/standard/deep
7. Conflict at Step 5 between authoritative ref and user answer surfaces 3 options
8. Step 7.1 coverage block fires if SC has no REQ
9. Step 7.4 re-runs coverage on user edit
10. Step 8 archives research, writes tombstone, offers git-commit
11. `/gabe-scope-change` with Primary-User change routes to pivot
12. `/gabe-scope-change` with new-REQ routes to addition
13. Session pause on Step 3, resume on Step 4 with markers visible
14. `--force` escape works on coverage block
15. Start-over requires typed confirmation + archives to tombstone

**DoD:**
- [ ] All 15 regression checks pass
- [ ] Integration edits land in all 6 existing commands
- [ ] Option A/B decision made and executed
- [ ] `install.sh` updated and tested on a fresh `~/.claude/`
- [ ] Final git commits in both repos
- [ ] PR-ready state

---

## 5. Testing Strategy (3 layers)

### Layer 1 — Prompt-unit tests
Per prompt: 3–5 fixtures × rubric scoring. Rubrics assert shape + constraints, not exact text. Token-budget assertions. Re-run on any prompt edit. Failure = hard stop.

### Layer 2 — Workflow integration test
- **Dogfood project:** `/home/khujta/projects/apps/ai-app/` in dry-run mode. Backup `.kdbp/`, run `/gabe-scope` from scratch, compare to existing `BUILD-GUIDE-V2` + `.kdbp/PLAN.md`.
- **Synthetic scenario:** "bookmark manager" greenfield transcript with all 5 core answers + likely follow-ups. Replayable deterministically.

### Layer 3 — Regression checklist
15-item checklist in Phase 7 DoD above.

---

## 6. Two-Repo Sync Plan

Mirror per phase DoD (not at the end). Only `commands/`, `templates/`, `schemas/` mirror to refrepos. `prompts/` and `tests/` are build-time assets staying in `gabe_lens/` unless Phase 7 decides Option A (ship to `~/.claude/prompts/`).

---

## 7. Progress Log

Append entries here as phases complete. Format: `[YYYY-MM-DD] Phase N: summary. Hours: X. Blockers: Y.`

- `[2026-04-21] Phase 1: Scaffolding + Prompt Test Harness — DONE. Harness infra (run.sh, lib/call-llm.sh, lib/score.sh) works; placeholder prompt fails 4/5 assertions across all 5 fixtures with exit code 1, proving scoring logic is bidirectional. 7 assertion types implemented (output_is_json, field_exists, field_in_set, contains_phrase, absent_phrase, max_chars, min_chars). Real-LLM path stubbed with curl + anthropic API but untested (mock-mode sufficient for P1 DoD). Rubric content remains authored against placeholder; real rubrics arrive in Phase 3 after Phase 2 data contracts. Hours: ~2. Blockers: none.`
- `[2026-04-21] Phase 2: Templates + Schemas — DONE. SCOPE.md + ROADMAP.md templates freeze with stable-anchor conventions ({#req-NN}, {#sc-NN}, {#phase-N}) plus per-phase Why-business-intent paragraphs (high-value for future /gabe-teach SCOPE mode). Added ROADMAP.md + SCOPE.md .example.md filled with bookmark-manager scenario for schema testing. scope-references.yaml canonical example covers 4 weights × 3 load_modes. JSON Schemas for session and references catch 6/6 and 5/5 violations in broken fixtures (bidirectional validation proven). 15-min downstream read-needs review documented in scope-data-contracts.md — key find: /gabe-teach SCOPE mode unlocks require per-phase Why paragraph; /gabe-plan + /gabe-align drift detection require REQ anchors. Mirror to refrepos/setup/cherry-pick/kdbp/{templates,schemas}/. Hours: ~3. Blockers: none.`
- `[2026-04-21] Phase 3: Prompt Authoring — STRUCTURE DONE. All 12 prompts written (7 Opus: intake-quality-evaluator, brainstorm-analyst, success-criteria-generator, non-goals-generator, req-decomposer, phase-skeleton-and-populator, scope-change-classifier · 5 Sonnet: intake-summary-assembler, users-and-non-users-drafter, constraints-and-posture-drafter, reference-summarizer, final-assembler). Per-prompt fixtures under fixtures/<prompt-id>/ — 27 total fixtures covering spec/idea/edge cases. Rubrics validate output shape, required fields, token budgets, absent markdown fences. 27/27 mock-mode runs PASS. Harness bugs surfaced + fixed: jq '//' treats false as null (replaced with type check) and string-vs-int field_in_set comparison (added tostring coercion). Classifier's 20-scenario suite: 5 physical fixtures + SCENARIOS.md reference for remaining 15 (to be exercised at real-LLM validation before Phase 6). DEFERRED: real-LLM validation (Phase 3.5) — requires ANTHROPIC_API_KEY + ≥3 runs per prompt at temp=0 to prove deterministic passes. Cost estimate ~$1-2 total. Hours: ~5. Blockers: none. No refrepos mirror (build-time asset per Option A).`
- `[2026-04-21] Phase 3.5 (partial): /gabe-review pass triaged 8 findings; fixed 7 of 8. (1) Anchors — SCOPE.md + example now emit per-entity {#ng-NN}/{#sr-NN}/{#oq-NN} matching scope-data-contracts.md declaration; (2) scope-references.yaml — header comment clarifies paths are illustrative; (3) prompts/README.md — documented token_budget (tokens) vs max_chars (chars) with 4:1 ratio and per-type deviation guidance; (4) scope-change-classifier bumped v1→v2: rule 6 extended to cover NEW authoritative refs that conflict with existing decisions, added rules 8 (constraint infeasibility) and 9 (timeline forces phase skip); SCENARIOS.md now 23 scenarios; acceptance gate updated to 22/23; (5) final-assembler rubric — new markdown_anchors_resolve assertion type verifies every same-file [link](#x) resolves to a {#x} definition in scope_md; (6) call-llm.sh real-mode path hardened — captures HTTP status, fails with exit 2 on non-200 or malformed response (no more silent EMPTY_RESPONSE); (7) run.sh awk frontmatter parser — added explicit scope comment (nested objects not supported; escalation path is python-yaml). BLOCKED: #1 real-LLM validation — no ANTHROPIC_API_KEY in environment. 27/27 mock fixtures still PASS after changes. Hours: ~1.5. Blocker surface: user must set ANTHROPIC_API_KEY to enable real-LLM validation before Phase 4 ships.`
- `[2026-04-21] Phase 3.5 (complete): Real-LLM validation via subagent path (no API key needed — subscription-authenticated Agent tool instead of curl + ANTHROPIC_API_KEY). 12 subagents spawned in 3 parallel batches of 4, each reading a prompt file + its fixtures, producing rubric-conforming output, writing to _out/REAL/, running score.sh. Result: 26/26 physical fixtures PASS across all 12 prompts. Classifier 5/5 correct classifications (rubric accepts both ref_conflict and ref_downgrade for v2 backward-compat). final-assembler's new markdown_anchors_resolve assertion passed — real anchors resolve in real output. NEW FINDING: phase-skeleton-and-populator produced 4 phases for "standard" granularity (prompt rule says 5-8) — rubric has no phase-count assertion, Phase 4 runtime check will enforce. 18 classifier reference-only scenarios (fixtures 6-23 in SCENARIOS.md) still deferred to Phase 6 ship gate. Hours: ~0.5 (subagent validation + result collection). Blocker retired. Phase 4 unblocked.`
- `[2026-04-21] Phase 4: /gabe-scope command spec Steps 0-6 — DONE (spec only; no runtime yet). Wrote commands/gabe-scope.md (~230 lines) covering: Step 0 re-invocation (4-case matrix + typed-confirm start-over + tombstone archival), Step 0.5 Reference Frame Setup (auto-suggest FS scan + manual entry + summarize-mode Sonnet cache), Step 1 intent capture (5 core + up to 10 follow-ups + brainstorm sub-loop with hard 2-cycle cap), Step 2 research fan-out (width prompt quick/standard/deep + parallel Sonnet agents + Opus synthesis), Step 3 problem+vision draft, Step 4 users+non-users (non-empty non_users enforced via Opus escalation), Step 5 SCs+non-goals (conflict-surface at authoritative-ref violations), Step 6 constraints+posture. Universal conventions: conflict-surfacing 3-option prompt (accept/override/pause), session.json atomic writes + schema validation after every write, [PENDING APPROVAL — step-N] marker convention for in-file edits, LLM call accounting with running cost surfaced to user, error-handling matrix (retry-once + abort). Edge cases documented: no .kdbp/, existing SCOPE.md, 3+ skipped questions, >8 refs token bloat, corrupted brainstorm cycle counter. Command version v1.0-alpha.steps-0-6 (bumps to v1.0 when Step 7-8 land next phase). Hours: ~2. Blockers: none. Phase 5 (Step 7 REQs + Roadmap + Step 8 Finalize) next.`
- `[2026-04-21] Phase 5: Step 7 + Step 8 Finalize — DONE (spec appended to commands/gabe-scope.md; now v1.0). Step 7.1 REQ decomposition + deterministic coverage check (regenerate/add/force/back options); Step 7.2 granularity prompt (coarse/standard/fine/custom N between 2-20); Step 7.3 phase skeleton with P3.5-surfaced runtime phase-count check (expected range per granularity — closes the rubric gap); Step 7.4 populate-mode adds depends_on/parallel_with/covers_reqs + deterministic coverage check for reqs_uncovered and reqs_duplicated; Mermaid dependency graph generated deterministically, no LLM. Step 8 (a) final assembly via Sonnet (validation gate on sc/req/phase anchors + coverage_complete), (b) write finalized files with section-order regex check + remove all PENDING APPROVAL markers + init Change Log entries, (c) archive research to research/archive/{ts}/, (d) tombstone session.json to archive/tombstones/ + append scope_init row to CHANGES.jsonl, (e) update KNOWLEDGE.md Root artifacts section, (f) git-commit prompt with suggested message (no auto-push, no amend), (g) announce next steps pointing to /gabe-plan 1 + /gabe-scope-change + /gabe-teach scope. Command version v1.0 (alpha sessions require --start-over before resuming). Hours: ~1.5. Blockers: none. Phase 6 (auxiliary commands -change, -addition, -pivot) next.`
- `[2026-04-21] Phase 6: Auxiliary commands — DONE (specs). Three commands: (a) /gabe-scope-change meta-router: pre-flight checks + classifier invocation via prompts/scope-change-classifier.md (v2) + 3-option routing (proceed/override/cancel) + low-confidence warning + CHANGES.jsonl audit row on every routing decision; --force-addition/--force-pivot override flags require rationale, appended to Change Log. (b) /gabe-scope-addition: additive changes with decimal-ID phase insertion (no renumbering of existing integer IDs), Sonnet-drafted additions via detected type (REQ/SC-non-inverting/phase/ref/constraint/NG), coverage re-check after every addition, auto-detection of implicit pivots via mini-classifier on the drafted output (aborts back to -change if detected), roadmap_version bumps but scope version stays. (c) /gabe-scope-pivot: disruptive path — typed-confirm pivot (exact "pivot to v{N+1}") + full archival of v{N} to .kdbp/archive/v{N}/ (SCOPE.md, ROADMAP.md, scope-references.yaml, research/) + re-derivation of v{N+1} seeded with v{N} context but Opus explicitly told the new direction + Open Questions migration with per-OQ keep/resolve/drop prompt + pivot-specific Change Log entry + CHANGES.jsonl pivot row + --reuse-intake flag to skip interview re-check. Flag constraints: no --yes on pivot (must type confirmation). Invariants documented: SCOPE.md version stable on addition, bumps on pivot; prior REQ/phase IDs immutable. Hours: ~2. Blockers: none. Phase 7 (integration edits + dogfood validation) next.`

---

## 8. Open Decisions Deferred to Phase 7

1. **Ship prompts to user or inline at build time?** (Option A vs. Option B.) Decide after Phases 1–5 reveal iteration cadence.
2. **Whether to also create `/gabe-brief` lightweight predecessor** for users without clear intent. Out of scope for v1; revisit post-Phase 7 if demand shows.

---

## 9. Kickoff

Next action: begin **Phase 1 — Scaffolding + Prompt Test Harness**. Start with directory creation + README skeleton + a stub `run.sh` that can read a placeholder prompt and call Opus. Rubrics come last in Phase 1, after Phase 2 data-contracts doc.
