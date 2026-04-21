---
name: gabe-scope
description: "Backbone authoring command for the Gabe Lens suite. Produces SCOPE.md (stable premise) + ROADMAP.md (phase plan) for a new project. Multi-step, checkpoint-gated, Opus-reasoning + Sonnet-templating. Every major step requires explicit user approval before the next runs. Usage: /gabe-scope [--resume | --start-over]"
---

# Gabe Scope

The backbone authoring command. Produces two linked artifacts for a new project:

1. **`.kdbp/SCOPE.md`** — high-inertia premise. Problem, users, success criteria, requirements, constraints, posture. Changes only through `/gabe-scope-change`.
2. **`.kdbp/ROADMAP.md`** — medium-inertia phase plan. Derived from SCOPE.md. Changes as phases complete, split, or get inserted.

**Design principles** (see `docs/gabe-scope-design.md` for full spec):
- **Strict checkpoint gating.** Every step ends with explicit user approval before the next runs. No auto-ship mode.
- **Pause anywhere.** Session state persists to `.kdbp/scope-session.json` + in-file `[PENDING APPROVAL]` markers. Days-later resume works.
- **Reference Frame first.** Existing standards (AI stack docs, engineering practices, compliance frameworks) declared at Step 0.5 and threaded into every reasoning call.
- **Brainstorm on idea-quality answers.** If the intake evaluator flags an answer vague/hedged, the Socratic analyst sub-loop offers 2–3 framings with explicit tradeoffs. Hard 2-cycle cap.
- **Goal-backward success criteria.** Observable user truths, not implementation tasks.
- **100% coverage invariant.** Every SC covered by ≥1 REQ; every REQ maps to exactly one Phase. Finalize blocks otherwise (with documented `--force` escape).

**This command delivers Steps 0–6.** Step 7 (Requirements → Roadmap) and Step 8 (Finalize) land in the next phase.

## Procedure

### Step 0: Re-invocation check (pre-flight)

Runs only if `.kdbp/SCOPE.md` or `.kdbp/scope-session.json` already exists. Otherwise proceed to Step 0.5.

Parse `$ARGUMENTS` for flags: `--resume` forces resume path; `--start-over` forces fresh with typed-confirm.

**Case matrix:**

| SCOPE.md | session.json | Behavior |
|---|---|---|
| absent | absent | Proceed to Step 0.5 fresh |
| absent | present | Prompt: **R**esume (default) / **S**tart-fresh (archive session as tombstone) / **A**bort |
| present | absent | Prompt: **C**ontinue-to-planning (run `/gabe-plan`) / **H**ange-scope (run `/gabe-scope-change`) / **S**tart-over (typed confirm, archive SCOPE.md + ROADMAP.md) / **A**bort |
| present | present | Same as row above + resume option for session |

**Start-over flow:**
1. Emit one-line summary of what will be archived: "`SCOPE.md v1 (created 2026-04-21) + ROADMAP.md v1 + scope-references.yaml will move to .kdbp/archive/.` Type `start over` to confirm."
2. On typed confirm (exact match, case-insensitive), `mkdir -p .kdbp/archive/tombstones/{timestamp}/` and `mv` SCOPE.md + ROADMAP.md + scope-references.yaml + scope-session.json into it.
3. Never delete. Tombstones are permanent audit trail.

**Resume flow:**
1. Read `scope-session.json`. Validate against `schemas/scope-session.schema.json`.
2. Check `command_version` matches current command version. Mismatch → stop with: "Session created under `/gabe-scope v{X}`; current is v{Y}. Resume may produce inconsistent results. Options: (a) `--force-resume` (accept risk), (b) start fresh (archives session). Recommend: fresh."
3. Announce resumed step: "Resuming at Step {N} ({name}). Last update: {timestamp}."
4. Jump to that step.

### Step 0.5: Reference Frame Setup

Runs on fresh scope only (skipped on `--resume` if frame was already loaded).

**Flow:**

**(a) Auto-suggest candidates.** Deterministic filesystem scan — no LLM yet. Scan these locations for markdown + YAML files:

```bash
./docs/ ./_docs/ ./specs/ ../docs/
~/.claude/rules/ ~/.claude/skills/
# If ancestor path contains refrepos/, include refrepos/docs/
# Parent-project .kdbp/ if present
```

For each candidate, extract first `#` heading or first non-blank line as preview. Present:

```
Reference Frame candidates found:

  [1] ~/.claude/rules/common/coding-style.md
      "# Coding Style" — immutability, file size, error handling
  [2] ./docs/architecture-patterns.md
      "# Architecture Patterns" — project-level patterns ledger
  [3] refrepos/setup/ai-stack/README.md
      "# AI Stack (Gabe Lens)" — LLM integration patterns

Pick: `a <N>` to add, `bulk-add` for all, `s` to skip, `m` to enter manual entry, `done` to proceed.
```

**(b) Manual entry.** For refs not surfaced by auto-scan, prompt:

```
Enter ref:
  path  : <absolute local path | relative path | URL>
  role  : <one-line purpose, mandatory>
  weight: [a] authoritative (hard constraint) / [s] suggestive (soft default) / [c] contextual (framing only) — default s
  load  : [f] full_read / [i] index_only / [z] summarize (cached) — default based on file size (>3k tokens → summarize or index_only)
```

For `summarize` mode, invoke Sonnet via `prompts/reference-summarizer.md`. Cache summary to `scope-references.yaml`.

**(c) Confirm + write.** Display final frame. User approves → write to `.kdbp/scope-references.yaml`. Validate against `schemas/scope-references.schema.json` — reject on schema failure.

**Empty frame is valid.** "No references declared. Proceeding without framing block — all reasoning will be from intake + research only. Confirm? [Y/n]"

**Checkpoint 0.5:** Reference Frame committed. session.json updated: `reference_frame_loaded: true`, `current_step: step-1-intake`.

### Step 1: Intent Capture (variable-depth interview)

**Model:** Opus throughout (intake-quality-evaluator + brainstorm-analyst + intake-summary-assembler)

**Flow — 5 core questions + up to 10 follow-ups:**

```
Q1 (one-liner)      — "In one sentence, what are you building?"
Q2 (primary user)   — "Who hurts the most from not having this, and what are they doing today instead?"
Q3 (why now)        — "What changed in the world or your context that makes this buildable or necessary now?"
Q4 (success shape)  — "In 6 months, if this works, what's different? (observable, not aspirational)"
Q5 (anti-vision)    — "What would you refuse to build, even if users asked?"
```

User can type `skip` on any core question (records to Open Questions) or `pause` (saves session.json, exits command).

**Per-answer routing** (after each user reply):

1. Build input bundle: `{question, answer, prior_answers, reference_frame}`
2. Invoke `prompts/intake-quality-evaluator.md` (Opus). Get back `{quality, signals, gap_opened, gap_question, reference_conflict, notes}`.
3. Branch on `quality`:
   - **spec** → accept answer, advance to next question. If `gap_opened`, push `gap_question` onto follow-up queue.
   - **idea** → enter brainstorm sub-loop (§1.5 below).
4. If `reference_conflict.ref_id` set → surface conflict now (see **Conflict-surfacing** §).

**Follow-up cap:** max 10 signal-triggered follow-ups per session across all core questions. Track in `session.json.intake.follow_ups_asked`. When cap hit, announce: "Follow-up budget exhausted. Remaining gaps route to Open Questions."

#### §1.5 Brainstorm Sub-loop

Invoked only when `intake-quality-evaluator` returns `quality: idea`. Hard cap 2 cycles per question; enforced by reading `session.json.intake.brainstorm_cycles[question_id]`.

**Cycle N:**
1. Invoke `prompts/brainstorm-analyst.md` with `{question, answer, signals, cycle: N, prior_answers, reference_frame}`.
2. Render the analyst's acknowledgment + 2–3 framings (with gains/gives_up each) + probing question.
3. User options: `A`/`B`/`C` to pick a framing, `refine: <text>` to combine/modify, `reject` to reject all.
4. Incrementing logic:
   - **Pick / refine** → convert to spec-quality answer, return to main flow, mark `brainstorm_exit: false`.
   - **Reject** + cycle < 2 → increment cycle, re-invoke with same inputs + `cycle: 2`.
   - **Reject** + cycle == 2 → write to §14 Open Questions with `[UNRESOLVED — brainstorm exit]`, mark `brainstorm_exit: true`, advance to next core question.

Never exceed cycle 2. If the command somehow reaches a third invocation, abort with schema validation error (session.json cap catches this).

#### §1.end Summarize intake

After Q5 answered (or skipped) and follow-up queue drained:

1. Invoke `prompts/intake-summary-assembler.md` (Sonnet) with full `{interview_answers, brainstorm_results}`.
2. Render the structured summary.
3. **Checkpoint 1:** User reviews. Options: `approve`, `revise: <field>=<value>`, `abort`.
4. On approve, write summary to session.json + advance `current_step` to `step-2-research`.

### Step 2: Research fan-out + synthesis

**Model:** Sonnet for research agents; Opus for synthesis.

**(a) Research width prompt.** Before spawning:

```
Research width (default: standard):

  [q] Quick    (2 agents: domain + pitfalls)    — ~$0.05, ~1 min
  [s] Standard (4 agents: + stack, user-patterns) — ~$0.10, ~2 min  [default]
  [d] Deep     (5-6 agents: + integrations, competitive) — ~$0.20, ~3 min
```

User picks. Save to `session.json.research_width`.

**(b) Parallel fan-out.** Spawn agents via Task tool. Each writes to `.kdbp/research/{name}.md`:

| Agent | Scope | Width |
|---|---|---|
| domain | Similar products, what they got right/wrong | all |
| pitfalls | Known failure modes; post-mortem patterns | all |
| stack | Common tech choices; version-specific gotchas | standard+ |
| user-patterns | Onboarding, retention, engagement patterns | standard+ |
| integrations | Expected-partner APIs, webhooks, auth | deep |
| competitive | Competitors + positioning analysis | deep |

**(c) Synthesis.** Opus reads all research files + intake summary + reference frame. Writes `.kdbp/research/SUMMARY.md` with opinionated recommendations. Include token/cost counter.

**Checkpoint 2:** User reviews SUMMARY.md only (not raw agent outputs). Options: approve / request-additional-agent `<name>: <scope>` / abort. Approve advances.

### Step 3: Problem + Vision draft (§§1–3 of SCOPE.md)

**Model:** Opus. Single LLM call.

**Inputs:** `{intake_summary, research_summary, reference_frame}`.

**Outputs:** Draft markdown for SCOPE.md §1 (One-liner), §2 (Problem), §3 (Vision / North Star). Use template at `templates/SCOPE.md` — match exact section headings and anchor format.

**Write procedure:**
1. Read `.kdbp/SCOPE.md` if exists (partial draft from prior resumed step); else start from template.
2. Replace §1–3 content with generated draft.
3. Append `[PENDING APPROVAL — step-3]` marker immediately after §3's content.
4. Push marker entry to `session.json.pending_approval_markers`.

**Checkpoint 3:** User reviews SCOPE.md §1–3 in-file. Can edit directly — the marker tells the command which region is pending. On approve, remove marker + advance.

### Step 4: Users + Non-Users draft (§§4–6)

**Model:** Sonnet. One primary call; Opus escalation only if non_users empty.

**Inputs:** `{intake_summary, research_summary, reference_frame}`.

**Output contract from `prompts/users-and-non-users-drafter.md`:**
- `primary_user.role`, `.description`, `.jtbd` (≥1 entry, "When I...I want to...so I can..." format)
- `secondary_users` (optional array)
- `non_users` (≥2 entries, non-empty)

**Escalation:** if Sonnet returns `non_users: []` or `len < 2`, re-invoke with Opus using the same prompt + instruction "enumerate ≥3 likely non-user segments the user can refine."

**Write:** draft into §4–6 with `[PENDING APPROVAL — step-4]` marker. Checkpoint 4 approve-or-revise-or-abort.

### Step 5: Success Criteria + Non-Goals draft (§§7–8)

**Model:** Opus. Two calls.

**Highest-friction checkpoint by design** — this is the sign-off on *what counts as success*.

**(a) Success criteria.** Invoke `prompts/success-criteria-generator.md` with `{intake_summary, research_summary, reference_frame, primary_user, problem_statement}`.

Output: 3–10 SCs, each with `{id: SC-NN, statement, why, ref_conflict}`. Statement begins "A user can " and contains a bound.

**(b) Non-goals.** Invoke `prompts/non-goals-generator.md` with `{intake_summary, success_criteria, reference_frame, primary_user, non_users}`.

Output: 2–8 NGs, each with `{id: NG-NN, statement, rationale}`. Statement begins "We will not ".

**(c) Render + conflict check.** Write both sections to SCOPE.md with per-entity anchors (`{#sc-NN}`, `{#ng-NN}`). For each SC whose `ref_conflict.ref_id` is set → surface conflict prompt (see **Conflict-surfacing** §).

**Checkpoint 5:** approve / revise-SC `<id>` / revise-NG `<id>` / abort. Brainstorm sub-loop may fire on revise if user's revised answer is idea-quality.

### Step 6: Constraints + Architecture Posture draft (§§9–10)

**Model:** Sonnet. One call. Brainstorm only fires on revise if user-provided edits are idea-quality.

**Inputs:** `{intake_summary, research_summary, reference_frame, success_criteria}`.

**Output contract from `prompts/constraints-and-posture-drafter.md`:**
- `constraints`: tech_stack, budget, timeline, regulatory, team_size, infra (nulls for unknown, not omitted)
- `architecture_posture`: synchrony, topology, data_gravity, deployment_target, integration_surface

**Conflict check.** Before rendering, Opus-evaluate each authoritative ref entry against the draft constraints + posture. Any conflicts → 3-option conflict prompt (see **Conflict-surfacing** §).

**Write:** §9 table + §10 bullets with `{#constraints}` + `{#architecture-posture}` anchors. Marker `[PENDING APPROVAL — step-6]`.

**Checkpoint 6:** approve → advance `current_step: step-7.1-requirements`, hand off to next phase.

**End of Phase 4 procedure.** Step 7 (REQs + Roadmap) and Step 8 (Finalize) live in the next phase.

---

## Universal conventions

### Conflict-surfacing (Steps 5, 6)

When an authoritative reference frame entry conflicts with the user's direction, emit:

```
⚠ Conflict detected

  Your answer / draft:  {summary of user direction}
  Authoritative ref:    {ref-id} — {role}
  Conflicting passage:  {excerpt or summary from ref}

  Options:
    [a] Accept the ref — align my answer/draft to the ref
    [o] Override the ref — record override + rationale in SCOPE.md Change Log
    [p] Pause — I need to update the ref file first, then resume

Pick [a/o/p]:
```

On override, append to §15 Change Log a `{date, type: override, ref_id, rationale}` row AND update the ref entry's audit trail in scope-references.yaml with `overridden_at: {timestamp}`.

### session.json writes

The command writes session.json after every successful sub-step. Writes are atomic (write to tmpfile, `mv` into place) to survive crashes mid-checkpoint.

**Minimum writes per step:**
- `last_updated` (always)
- `current_step` (on advance)
- `completed_steps` (append on checkpoint approval)
- `prompt_versions_used` (merge on every LLM call)
- Step-specific payload (intake answers, brainstorm cycles, research_width, pending_approval_markers)

Validate the session.json against `schemas/scope-session.schema.json` after every write. Schema violation = abort with dump of the violating state to stderr.

### In-file `[PENDING APPROVAL — step-N]` markers

Each step's generated content is bracketed by a marker the user sees in their editor. Format:

```markdown
<!-- [PENDING APPROVAL — step-3] generated by /gabe-scope — do not edit the marker manually -->

## 1. One-liner {#one-liner}

{draft content user can edit}

<!-- [/PENDING APPROVAL — step-3] -->
```

On checkpoint approval, the command removes BOTH markers via Edit tool match-and-replace. User can move text outside the markers before approval — anything outside is treated as final.

### LLM call accounting

After every LLM call, update `session.json.cost_estimate`:
- `tokens_used` += input + output
- `estimated_usd` += per-model cost (Opus input ~$15/Mtok, output ~$75/Mtok; Sonnet input ~$3/Mtok, output ~$15/Mtok)

Surface running total after each checkpoint: "Step 3 complete. Session cost so far: $0.34 (12,400 tokens)."

### Error handling

| Error | Behavior |
|---|---|
| LLM call fails (network, rate-limit, 5xx) | Retry once with 30s backoff. Second failure → save session.json + exit with remediation message. |
| LLM returns non-conformant output (JSON parse fail, required field missing) | Retry once with "your previous response violated {X} — regenerate". Second failure → surface raw output + abort. |
| User types invalid checkpoint response | Re-prompt with allowed options. Don't advance. |
| session.json schema validation fails after write | Dump violating state to stderr. Do not lose user work — the current draft in SCOPE.md remains. |
| Reference frame path missing on resume | Prompt: re-link, downgrade to contextual, or remove. Do not silently drop a ref. |

---

## Edge cases

**No `.kdbp/` directory.** Command exits: "No KDBP detected. Run `/gabe-init` first." Do NOT auto-create.

**SCOPE.md exists + user types `/gabe-scope` (no args).** Step 0 case-3: show options. Default (press Enter) is **continue-to-planning** (`/gabe-plan`).

**User punts 3+ core questions via `skip`.** Announce: "You've skipped 3 of 5 core questions. The scope will have major gaps. Recommend pausing to gather intent first. Continue anyway? [y/N]" Default No.

**Reference frame has >8 refs.** Warn: "Framing block for every LLM call will exceed token budget. Consider downgrading some to `contextual` or removing." Do not auto-reduce.

**Brainstorm cycle counter corrupted.** If session.json shows `brainstorm_cycles[q] > 2`, treat as schema violation (§ error handling row 4). Do not trust the value.

---

## Integration with the suite

- **`/gabe-plan <phase-id>`** is called AFTER `/gabe-scope` finalizes (Step 8 in next phase). Does not interact with in-progress scope sessions.
- **`/gabe-align`, `/gabe-review`, `/gabe-commit`** read SCOPE.md + ROADMAP.md for drift detection. None write. `/gabe-commit` audit warns on direct edits (bypass of `-change`).
- **`/gabe-teach`** (SCOPE mode, future Phase 7) re-reads sections for lessons.
- **`/gabe-scope-change`** is the only write path post-finalize. Runs from any step — if invoked mid-session, tells user to finish or abort the in-progress session first.

---

## Command version

This command: `v1.0-alpha.steps-0-6`. Steps 7–8 land in next phase. Once 7–8 land, version bumps to `v1.0`.

Session files created under `v1.0-alpha.*` may refuse to resume against future `v1.0` command without `--force-resume` flag.
