# /gabe-scope Design Spec v0.3

**Status:** Draft v0.3 — ready for implementation planning
**Date:** 2026-04-21
**Authors:** brownbull + Claude (design session)

**v0.3 changes from v0.2:**
- New **§2.5 — Reference Frame** — first-class support for existing standards/docs (AI stack, agent engineering practices, compliance frameworks, etc.) that should influence the scope
- New **Step 0.5 (Reference Frame Setup)** — before intake, user declares reference docs with role + weight (authoritative/suggestive/contextual); auto-suggest scan offers candidates
- All Opus/Sonnet calls now receive a Reference Frame system block; authoritative refs flagged as hard constraints, conflicts surfaced mid-flow
- SCOPE.md gets a new **Reference Frame** section (§0, before One-liner) recording what framed the scoping
- SCOPE.md frontmatter gets `reference_frame_file: .kdbp/scope-references.yaml`

**v0.2 changes (retained):**
- D7 → artifact split into `SCOPE.md` (stable) + `ROADMAP.md` (more fluid)
- D2 → variable-depth interview with signal-based follow-ups
- D3 → user picks research width upfront (quick/standard/deep)
- D5 → phase-split options offered after REQ generation
- D6 → hybrid skeleton → populated roadmap
- D8 → single `/gabe-scope-change` meta-command with Opus classifier
- D10 → dual resume: JSON state + `[PENDING APPROVAL]` markers in-file
- §3.5 — Brainstorm Sub-Loop for idea-not-spec answers (BMAD's analyst persona)
- §4.0 — Re-invocation Flow

---

## 1. Purpose & Principles

`/gabe-scope` is the **backbone command** for a new project. It produces two durable artifacts:

1. **`SCOPE.md`** — high-inertia; defines *what we are building and why*. Changes only through `/gabe-scope-change`.
2. **`ROADMAP.md`** — lower-inertia; defines *how we'll build it in phases*. Updated as phases complete, split, or get inserted.

### Principles

- **High inertia on SCOPE.md, medium on ROADMAP.md.** The premise is stable; the plan is living.
- **Thoughtful over fast.** This command spends compute liberally — Opus for reasoning, Sonnet for drafting, parallel research agents, multiple LLM (Large Language Model) calls. Budget target: ~$0.30–$1.00 per project scoping (one-time).
- **Structured output, with controlled extensibility.** Baseline template is mandatory. User can add `custom_sections:` between Constraints and Requirements.
- **Multi-step with strict checkpoints.** User gates every major step. Sessions can pause and resume across days.
- **Brainstorm when ideas aren't specs.** If the user answers with an idea (vague, hedged, short), the command enters an analyst sub-loop before accepting the answer.
- **Goal-backward.** Success criteria are observable user truths, not implementation tasks.
- **100% coverage.** Every stated requirement maps to exactly one phase. No orphans.
- **Change log is the source of truth for evolution.** Additions and pivots append to a change log — never silently rewrite sections.

### Non-goals

- NOT a technical implementation plan. That's `/gabe-plan`'s job. SCOPE.md carries *architecture posture* (high-level), not *architecture detail* (module boundaries, file layouts).
- NOT a brainstorming tool from scratch. The brainstorm sub-loop (§3.5) refines underspecified answers — it doesn't generate a premise from zero. Users should arrive with at least an intent.
- NOT automatic. No auto-ship mode. User approves every step.

---

## 2. The Command Family

| Command | When to invoke | What it produces | LLM budget |
|---|---|---|---|
| **`/gabe-scope`** | Once per project, at inception | `SCOPE.md` v1 + `ROADMAP.md` v1 | $0.30–$1.00 |
| **`/gabe-scope-change`** | Any time scope needs change | Opus classifies → routes to addition or pivot | $0.02 (classifier) + downstream |
| **`/gabe-scope-addition`** *(routed via -change)* | Additive changes — new REQs, new phases, no direction shift | Appends to SCOPE.md change log; extends REQ list; inserts phases with decimal IDs in ROADMAP.md | $0.05–$0.15 |
| **`/gabe-scope-pivot`** *(routed via -change)* | Direction change — primary user, non-goals, success criteria, posture | Archives SCOPE.md → `SCOPE.v{N}.md` + ROADMAP.md → `ROADMAP.v{N}.md`; creates v{N+1} with pivot rationale | $0.15–$0.40 |

### Pivot-trigger rules (Opus classifier in `/gabe-scope-change`)

Change classifies as **pivot** if it touches any of:
- Primary User (Section 4 of SCOPE.md)
- A Non-User becomes a Primary/Secondary User, or vice versa (Section 6)
- A Success Criterion is removed, inverted, or has its observable-truth flipped (Section 7)
- A Non-Goal becomes a Goal, or a Goal becomes a Non-Goal (Sections 7 + 8)
- Architecture Posture macro-shift — sync↔async, monolith↔multi-agent, local↔cloud-first (Section 10)
- An **authoritative** Reference Frame entry is replaced, downgraded, or its binding is overridden (see §2.5)
- Funding/business model shift noted by user that retargets the product

Otherwise: **addition**. Classifier outputs rationale so user sees *why* it routed the way it did. User can override with `--force-addition` or `--force-pivot`.

---

## 2.5. Reference Frame — Existing Standards & Docs

**The problem.** Real projects never start from a blank slate. The user often has existing documents that should frame the scope: the AI stack they've standardized on (e.g., Gabe Suite docs), engineering practices they follow (e.g., agent engineering maturity model from the hackathon analysis), compliance frameworks, prior art, wireframes, user research. Asking Opus to rediscover these through interview is wasteful and lossy. Asking the user to paste them inline is awkward and token-heavy.

**The idea.** A **Reference Frame** is a declared set of external documents with explicit role + weight, loaded once at Step 0.5 and threaded into every subsequent LLM call as framing material.

### Schema

Stored at `.kdbp/scope-references.yaml`:

```yaml
references:
  - id: ref-01
    path: /home/khujta/projects/refrepos/docs/hackathon-analysis/agent-engineering/
    role: "Agent engineering maturity model and practices we follow"
    weight: authoritative
    load_mode: index_only    # full_read | index_only | summarize
  - id: ref-02
    path: /home/khujta/projects/refrepos/setup/ai-stack/README.md
    role: "AI stack commitments (Claude models, PydanticAI, Langfuse, SSE)"
    weight: authoritative
    load_mode: full_read
  - id: ref-03
    path: ./docs/existing-wireframes/
    role: "UX direction from design sprint"
    weight: suggestive
    load_mode: summarize
  - id: ref-04
    path: https://company-wiki/compliance-v3
    role: "Regulatory framing"
    weight: contextual
    load_mode: summarize
```

### Weight semantics

| Weight | Binding | Opus behavior |
|---|---|---|
| **authoritative** | Hard constraint | Draft sections must honor the ref; conflicts between user answer and ref surface explicitly ("Your answer X appears to conflict with authoritative ref Y — override, update-ref, or reconsider?"); violating an authoritative ref without user override is a Step-8 finalize blocker |
| **suggestive** | Soft default | Draft sections prefer the ref's direction; deviations annotated in draft ("Deviating from ref-03 suggestion because…"); user can accept or adjust |
| **contextual** | Framing only | Read for domain/vocabulary alignment; not a binding constraint; used to shape tone and terminology |

### Load modes

| Mode | When to use | Cost |
|---|---|---|
| **full_read** | Short docs (<3k tokens) and authoritative refs | Ref loaded verbatim into every relevant LLM call |
| **index_only** | Directories or large doc sets — just pass a list of file paths + one-line descriptions; Opus can choose to read further via tool use | Cheap; risks Opus missing relevant content |
| **summarize** | Large single docs — one-time Sonnet summarization at Step 0.5, summary cached and threaded | Moderate one-time cost; thereafter cheap |

### Threading into LLM calls

Every reasoning call gets a **Reference Frame system block**:

```
## Reference Frame (loaded for this scoping)
- [authoritative] ref-02 (ai-stack/README.md, full_read):
    {full content or summary}
- [authoritative] ref-01 (agent-engineering, index_only):
    {index of files with one-line descriptions}
- [suggestive] ref-03 (wireframes, summarize):
    {cached summary}
- [contextual] ref-04 (compliance, summarize):
    {cached summary}

When drafting or reasoning about this scope:
- Authoritative refs are hard constraints. Flag any user answer that conflicts with an authoritative ref.
- Suggestive refs shape defaults. Annotate deviations.
- Contextual refs align vocabulary and framing only.
```

### Conflict surfacing

At Steps 5 (Success Criteria), 6 (Constraints & Posture), and 7 (Requirements), Opus runs an explicit conflict check against **authoritative** refs. If a conflict is detected:

```
⚠ Conflict detected:
  Your answer: {summary of user's direction}
  Authoritative ref (ref-02, ai-stack): {relevant passage}
  Options:
    A. Override the ref (recorded in Change Log with rationale)
    B. Adjust your answer to align with the ref
    C. Pause — update the ref file itself first, then resume
```

User picks. Override is recorded in SCOPE.md's Change Log AND in the reference entry's audit trail.

### In SCOPE.md

A new **§0 — Reference Frame** section appears before the One-liner, listing the refs used with their weight and role. Future readers see the framing at a glance. If a ref is later downgraded (authoritative → suggestive) or removed, that's a pivot-trigger (per §2 pivot rules).

---

## 3. The Artifacts

### 3a. `SCOPE.md` (stable backbone)

Canonical location: `.kdbp/SCOPE.md`.

#### Frontmatter

```yaml
---
name: <project name>
version: 1                   # bumps only on pivot
status: active               # active | pivoted | archived
created: 2026-04-21
last_scope_event: 2026-04-21 # updates on any addition or pivot
primary_user: <one-liner>
project_kind: agent-app | web-app | cli | library | other
custom_sections: []          # D12 — user-defined section names, inserted between Constraints and Requirements
roadmap_file: .kdbp/ROADMAP.md
reference_frame_file: .kdbp/scope-references.yaml
---
```

#### Sections (in order)

0. **Reference Frame** — Refs used to frame the scoping, with weight + role (per §2.5). Mandatory if `scope-references.yaml` is non-empty.
1. **One-liner** — Pitch in ≤25 words.
2. **Problem** — What pain, who feels it, evidence.
3. **Vision / North Star** — Where this goes in 1–3 years.
4. **Primary User & Jobs-to-be-Done** — Single most important user; JTBD in "when I {context}, I want to {action}, so I can {outcome}" format.
5. **Secondary Users** *(optional)* — Ranked below primary.
6. **Non-Users** — Explicitly NOT for these people. (Mandatory — can't be empty.)
7. **Success Criteria** — Observable user truths, 5–10. Format: "A user can {observable action} within {constraint}."
8. **Non-Goals** — What we explicitly won't build, each paired with *why*.
9. **Constraints** — Tech, budget, timeline, regulatory, team, infra.
10. **Architecture Posture** — High-level: sync/async, mono/multi-agent, data gravity, deployment target.
11. *(Custom sections, if `custom_sections:` in frontmatter.)*
12. **Requirements** — `REQ-01`..`REQ-N`, each tagged with which Success Criterion it covers.
13. **Strategic Risks** — Premise-level, not implementation-level. Severity + mitigation posture.
14. **Open Questions** — Unresolved items, including any `[UNRESOLVED — brainstorm exit]` markers from §3.5.
15. **Change Log** — Append-only. Each entry: date, type (`init | addition | pivot`), summary, diff pointer.

#### Coverage matrix (embedded)

```
Success Criterion → REQ mapping   (every SC has ≥1 REQ)
REQ → Phase mapping               (every REQ has exactly 1 Phase — lives in ROADMAP.md)
```

Command blocks finalize if coverage is incomplete, with a documented `--force` escape for exploratory scopes.

---

### 3b. `ROADMAP.md` (phase plan, more fluid)

Canonical location: `.kdbp/ROADMAP.md`.

#### Frontmatter

```yaml
---
scope_file: .kdbp/SCOPE.md
scope_version: 1
roadmap_version: 1           # bumps on any -change (addition OR pivot)
granularity: standard        # coarse | standard | fine (user pick — D5)
phases_total: 7
phases_complete: 0
created: 2026-04-21
last_change: 2026-04-21
---
```

#### Sections

1. **Granularity** — `coarse (3–5) | standard (5–8) | fine (8–12)`; chosen at Step 7.
2. **Phase Table** — `ID | Name | Goal | Status | Parallel-with | Depends-on | Covers-REQs`.
   - Integer IDs (1, 2, 3, …) for root phases.
   - Decimal IDs (1.1, 2.3, …) reserved for `-addition` insertions.
3. **Dependency Graph** — Optional Mermaid diagram auto-generated from Depends-on + Parallel-with columns.
4. **Coverage Matrix** — `REQ-ID → Phase-ID` for audit.
5. **Roadmap Change Log** — Append-only; separate from SCOPE.md's change log. Tracks phase splits, merges, insertions, reorderings, and the `-change` event that caused each.

`/gabe-plan <phase-id>` reads ROADMAP.md to find the phase + its Covers-REQs, then reads SCOPE.md for the REQ text, then writes `.kdbp/plans/phase-{id}-PLAN.md`.

---

## 3.5. Brainstorm Sub-Loop ("idea, not spec")

**The problem:** Users often arrive with an idea, not a spec. "I want something like X for Y" is valuable intent but not a committable Success Criterion. The command must either refine the idea into a spec or mark it explicitly unresolved — never silently freeze a vague answer.

**The pattern:** Inspired by BMAD's **Mary (Analyst persona)** — a Socratic, non-judgmental interlocutor who probes. GSD's `questioning.md` has a lighter version; RALPH and PRP mostly don't brainstorm (they accept thin answers and ground via research).

### Detection signals (when to trigger)

The command evaluates each user answer against heuristics:

- **Length** — answer < 15 words (configurable per question)
- **Hedge words** — "maybe", "something like", "I think", "not sure", "probably", "kind of"
- **Abstract nouns without concretization** — "flexibility", "scalable", "good UX" without examples
- **Answer is itself a question** — "what do you think?", "I don't know, what's common?"
- **Self-contradiction** — two clauses in one answer that conflict

Any signal ≥ threshold → enter brainstorm sub-loop for that question. Opus (not a separate agent) runs the sub-loop.

### Sub-loop flow

1. **Acknowledge + reframe.** Opus restates what it heard in the most charitable interpretation: "Let me play back — you're imagining {summary}. Fair?"
2. **Offer 2–3 framings/directions.** Concrete, differentiated options. Each option states: the framing, what it implies downstream, what it rules out.
3. **User picks / refines / rejects all.**
   - Pick → convert framing into spec-quality answer, return to main flow.
   - Refine → user types a combination or modification; Opus converts to spec.
   - Reject all → Opus asks ONE more probing question (why none of the options fit).
4. **After ONE probing question:**
   - If new answer is spec-quality, return to main flow.
   - If still idea-quality, write the question + last answer + framings offered to Section 14 (Open Questions) with marker `[UNRESOLVED — brainstorm exit]`, return to main flow.

**Budget cap:** 2 brainstorm cycles per question maximum (reframe + 1 probing). Prevents runaway Socratic loops.

### Persona notes (for the Opus system prompt)

- Curious, not leading. Don't steer the user toward a "correct" answer; reveal the option space.
- Name tradeoffs explicitly. Every framing names what it gains and what it gives up.
- Acknowledge "I don't know yet" as valid. Uncertain answers go to Open Questions, not forced into the spec.
- Avoid jargon unless the user used it first.
- Ask one question at a time. No compound prompts.

### Example

> **Q (Step 5 — Success Criteria):** "In 6 months, what's different if this works?"
> **User:** "Users are happier, I think."
>
> **Signals fired:** length (5 words), hedge word ("I think"), abstract noun ("happier").
>
> **Brainstorm:**
> *"'Happier' can mean a lot of things. Let me offer three framings so we pick the one that matches your intent:*
> - *A. **Engagement** — users come back more often (DAU/MAU goes up). Implies you care about retention loops.*
> - *B. **Speed-to-outcome** — users accomplish their task in less time. Implies you care about latency/UX.*
> - *C. **Confidence** — users trust the output more (fewer manual reviews, fewer overrides). Implies you care about correctness/explainability.*
> *Which is closest, or is it something else?"*
>
> User picks (B) → success criterion becomes "A user can complete a triage submission end-to-end in ≤90 seconds, down from a current baseline of ~5 minutes."

---

## 4. Workflow — 8 Steps + Pre/Brainstorm

Each step writes intermediate state to `.kdbp/scope-session.json` AND places `[PENDING APPROVAL]` markers in the in-progress `SCOPE.md` so the user sees context visually (D10).

### Step 0 — Re-invocation Check (pre-flight)

Runs only if SCOPE.md or scope-session.json already exists.

**Cases:**

| Condition | Action |
|---|---|
| No SCOPE.md, no session.json | Proceed to Step 1 fresh |
| No SCOPE.md, session.json exists | "You have an in-progress scope session from {date}, last step {N}. Resume / restart-fresh (archive session as tombstone) / abort?" |
| SCOPE.md exists, no session.json | "You already have a finalized scope (v{N}). Options: **continue to planning** (run `/gabe-plan`) / **change scope** (run `/gabe-scope-change`) / **start over** (archives SCOPE.md + ROADMAP.md to `.kdbp/archive/`, wipes, starts fresh — require explicit confirm)" |
| Both exist | Same as above but session.json is also archived as tombstone |

User's "start over" always requires a typed-in confirmation (not one-keystroke). Tombstone archiving never deletes — always moves to `.kdbp/archive/tombstones/{timestamp}/`.

### Step 0.5 — Reference Frame Setup

Runs on fresh scope (skipped on resume).

**Flow:**

1. **Auto-suggest candidates.** Scan common locations for likely refs:
   - `./docs/`, `./_docs/`, `./specs/`
   - `../docs/`, repo-root `docs/`
   - `~/.claude/rules/`, `~/.claude/skills/`
   - `refrepos/docs/` if present in path ancestry
   - `.kdbp/` upstream (parent projects)

   Each candidate surfaces with filename + first-heading or first-line preview. User can `a` (add), `s` (skip), `bulk-add` (all), or `bulk-skip`.

2. **Manual entry.** User can add refs not found by auto-suggest:
   - Path (local or URL)
   - Role (one-liner, mandatory)
   - Weight: `authoritative | suggestive | contextual` (default: `suggestive`)
   - Load mode: `full_read | index_only | summarize` (Opus suggests default based on file size)

3. **Summarization pass** (only for `summarize` mode refs). Sonnet reads each and writes a summary cached alongside the ref entry in `scope-references.yaml`. Target summary length: ≤500 tokens per ref.

4. **Confirmation.** Show user the full Reference Frame with weights; user approves or edits.

**Can be empty.** If user has no refs to declare, proceed with an empty frame (no framing block injected into LLM calls). Explicit no-refs acknowledgment prevents the user from forgetting they have some and regretting it at Step 5.

**Checkpoint 0.5:** Reference Frame approved → committed to `.kdbp/scope-references.yaml`.

### Step 1 — Intent Capture (variable depth interview)

**Model:** Opus
**LLM calls:** 5–15 (one per question + brainstorm sub-loops as triggered)

Start with the **5 core questions** (spec v0.1):
1. One-liner
2. Primary user + pain
3. Why now
4. Success shape
5. The anti-vision

After each answer, Opus evaluates:
- **Quality signal** (see §3.5 detection).
- **Gap signal** — did the answer open a new thread that needs its own question? (e.g., mentioning a constraint that wasn't asked about.)

**Branch logic:**
- Answer is spec-quality + no new gaps → next core question
- Answer is idea-quality → brainstorm sub-loop (§3.5)
- Answer opens a new gap → insert a follow-up question before the next core question, up to a cap of +10 follow-ups across the whole interview

Total interview length: 5 (core) + up to 10 (follow-ups) = max 15 questions. Brainstorm cycles add their own LLM calls but do not count toward question limits.

User can `skip` any core question (punted to Open Questions section) or `pause` (saves session.json, ends command).

**Checkpoint 1:** Opus drafts structured intake summary. User approves / revises / aborts.

### Step 2 — Research Width Prompt + Parallel Fan-out

**Model:** Sonnet (researchers); Opus (synthesis)

Before spawning, ask user:

> "Research width (default: standard):
> - **Quick** (2 agents: domain + pitfalls) — ~$0.05, ~1 min
> - **Standard** (4 agents: + stack, user-patterns) — ~$0.10, ~2 min
> - **Deep** (5–6 agents: + integrations, competitive) — ~$0.20, ~3 min"

User picks width. Width selection is saved to session.json so `--resume` doesn't re-prompt.

Spawn agents in parallel. Each writes to `.kdbp/research/{name}.md`. Opus synthesizes → `.kdbp/research/SUMMARY.md`.

**Checkpoint 2:** User reviews SUMMARY.md only. Approves / revises / aborts. Can request additional agents on top of SUMMARY ("add a regulatory agent") — triggers incremental fan-out.

### Step 3 — Problem & Vision Draft

**Model:** Opus | **LLM calls:** 1

Drafts SCOPE.md Sections 1–3. Short, evidence-linked.

**Checkpoint 3:** In-file approval — user edits directly in SCOPE.md draft, removes `[PENDING APPROVAL]` marker when done.

### Step 4 — Users & Non-Users

**Model:** Sonnet | **LLM calls:** 1

Drafts Sections 4–6. **Non-Users cannot be empty** — if Sonnet produces an empty section, Opus is escalated to enumerate likely non-users based on intake + research; user confirms each.

**Checkpoint 4:** In-file approval.

### Step 5 — Success Criteria & Non-Goals

**Model:** Opus | **LLM calls:** 2

Highest-friction checkpoint by design. Goal-backward criteria; non-goals with "why we said no." Brainstorm sub-loop fires aggressively here — vague success criteria are the most common scope-rot vector.

**Checkpoint 5:** In-file approval. This is the sign-off on *what counts as success*.

### Step 6 — Constraints & Architecture Posture

**Model:** Sonnet | **LLM calls:** 1 (+ brainstorm if fired)

Constraints synthesized from intake + research + direct follow-ups. Architecture posture is macro-level only.

**Checkpoint 6:** In-file approval.

### Step 7 — Requirements → Phase Split → Roadmap (hybrid, per D6)

**Model:** Opus | **LLM calls:** 3

**Step 7.1 — Requirements generation.**
Opus generates `REQ-01`..`REQ-N`, each tagged with the Success Criterion it covers. User reviews; can edit, add, or remove REQs.

**Checkpoint 7.1:** REQ list approved. Coverage check: every SC has ≥1 REQ.

**Step 7.2 — Phase split options (per D5).**
Ask user:

> "How should we split into phases?
> - **Coarse** (3–5 phases, milestone-sized)
> - **Standard** (5–8 phases, sprint-sized) — *recommended*
> - **Fine** (8–12 phases, iteration-sized)
> - **Custom** — enter a target count"

User picks. Granularity saved to ROADMAP.md frontmatter.

**Step 7.3 — Phase skeleton.**
Opus proposes a skeleton: just `ID | Name | Goal` at the chosen granularity. No Depends/Parallel/Covers yet.

**Checkpoint 7.3:** User approves skeleton. Can request a different granularity (→ re-run 7.3) or edit phase names/goals in place.

**Step 7.4 — Populate skeleton.**
Opus fills in `Depends-on`, `Parallel-with`, `Covers-REQs` for the approved skeleton. Coverage validation runs: every REQ assigned to exactly one phase; every phase's goal = union of its REQ outcomes.

**Checkpoint 7.4:** User reviews populated roadmap. Can move REQs between phases, reorder, adjust dependencies. Coverage check re-runs on any edit.

### Step 8 — Finalize

**Model:** Sonnet | **LLM calls:** 1

- Assemble final `SCOPE.md` with coverage matrix + frontmatter.
- Assemble final `ROADMAP.md` with phase table + dependency graph + roadmap coverage matrix.
- Write Change Log entries: `init` in both.
- Move `.kdbp/research/` → `.kdbp/research/archive/` (per D11).
- Delete `.kdbp/scope-session.json`; write tombstone marker to `.kdbp/archive/tombstones/scope-session-{timestamp}.json` with summary.
- Prompt user for git commit (not auto-commit).
- Update `.kdbp/KNOWLEDGE.md` with pointers to SCOPE.md and ROADMAP.md as root artifacts.
- Announce: "Next: `/gabe-plan 1` to decompose Phase 1 into tasks. Or `/gabe-scope-change` if you need to adjust scope."

**Checkpoint 8:** Final review + approval. SCOPE.md freezes; ROADMAP.md remains editable through `/gabe-scope-change`.

---

## 5. Model Tier Policy

| Step | Model | Why |
|---|---|---|
| Step 0 (re-invocation) | (no LLM) | Deterministic file checks |
| Step 0.5 auto-suggest scan | (no LLM) | Deterministic filesystem scan |
| Step 0.5 summarization (for `summarize` mode refs) | Sonnet | One-time per ref; summary is cached |
| Step 1 intake | Opus | Empathic questioning + answer-quality evaluation |
| Step 1 brainstorm sub-loop | Opus | Socratic/analyst behavior |
| Step 1 intake summary | Opus | Faithful compression across many turns |
| Step 2 research agents | Sonnet | 2–6 parallel agents — cost-sensitive |
| Step 2 research synthesis | Opus | Cross-report reasoning |
| Step 3 problem/vision | Opus | Premise-setting |
| Step 4 users/non-users | Sonnet | Template-driven |
| Step 4 non-user enumeration (escalation) | Opus | Reasoning when Sonnet fails to fill |
| Step 5 success criteria | Opus | Goal-backward is hard |
| Step 5 non-goals | Opus | Reasoning about "why we said no" |
| Step 6 constraints/posture | Sonnet | Summarization |
| Step 7.1 REQ generation | Opus | Decomposition |
| Step 7.3 skeleton | Opus | Phase-shape reasoning |
| Step 7.4 population | Opus | Dependency reasoning |
| Step 8 assembly | Sonnet | Templating |
| `/gabe-scope-change` classifier | Opus | Nuanced pivot-vs-addition call |
| `/gabe-scope-addition` drafting | Sonnet | Additive edits |
| `/gabe-scope-pivot` drafting | Opus | Re-derivation of downstream sections |

**Haiku is not used in this family.** Backbone documents are worth paying for.

---

## 6. Integration with the Suite

- **`/gabe-plan <phase-id>`** reads ROADMAP.md to find the phase + Covers-REQs, then reads SCOPE.md for the REQ text, then writes `.kdbp/plans/phase-{id}-PLAN.md`.
- **`/gabe-teach`** gains a **SCOPE mode** (re-read sections of the user's own SCOPE.md/ROADMAP.md) alongside existing ARCH mode.
- **`/gabe-align`** (existing) becomes the watchdog for drift between shipped code and declared scope — flags when code implements outside any REQ or a phase completes without satisfying its Covers-REQs.
- **`/gabe-review`** checks diffs against the current phase's REQ IDs; surfaces REQ drift or inflation.
- **`/gabe-commit`** audit extended: if a commit directly modifies SCOPE.md or ROADMAP.md (bypassing `/gabe-scope-change`), warn and suggest the proper command. Routine edits to `.kdbp/plans/phase-*-PLAN.md` remain unrestricted.
- **`/gabe-push`** runs a coverage-drift check as part of pre-push validation.

The division of labor per the user's guidance:
- **`/gabe-scope` family** = authoring scope + roadmap
- **`/gabe-align`, `/gabe-review`, `/gabe-commit`** = guarding scope vs. reality; no drift detection inside `/gabe-scope` itself

---

## 7. Decisions — Locked

| # | Decision | Choice | Rationale |
|---|---|---|---|
| D1 | Artifact location | **A.** `.kdbp/SCOPE.md` + `.kdbp/ROADMAP.md` | Consistent with suite |
| D2 | Interview depth | **B.** Variable with signal-based follow-ups (5 core + up to 10 follow-ups = max 15) | Better coverage without over-asking |
| D3 | Research width | **User-prompted** (quick/standard/deep) | User-agency; cost-transparent |
| D4 | Checkpoint gating | **A.** Strict per-step | Matches high-inertia principle |
| D5 | Roadmap granularity | **User-prompted at Step 7.2** (coarse/standard/fine/custom) | Explicit choice after REQs are known |
| D6 | Phase derivation | **C.** Hybrid skeleton → populated | Context-coherent yet controllable |
| D7 | Artifact split | **Separate ROADMAP.md** | SCOPE stable, ROADMAP fluid |
| D8 | Addition vs. pivot | **B.** `/gabe-scope-change` meta-command with Opus classifier | User declares intent to change; classifier names the severity |
| D9 | Model tier | **A.** Mixed (Opus-reasoning, Sonnet-templating) | Per-step table in §5 |
| D10 | Resume mechanism | **C.** Both — JSON state + `[PENDING APPROVAL]` in-file markers | Machine resume + visual context |
| D11 | Research retention | **C.** Archive to `.kdbp/research/archive/` on finalize | Audit + regeneratable on pivot |
| D12 | Custom sections | **A.** Yes, between Constraints and Requirements, via frontmatter list | Controlled extensibility |

---

## 8. Risks

| Risk | Likelihood | Severity | Mitigation |
|---|---|---|---|
| Workflow too heavy — users skip it | Medium | High | Strict checkpoint design means aborting early is cheap; brainstorm sub-loop handles the "I don't know everything" case well |
| Opus cost surprises users | Low | Medium | Surface running cost estimate after each step; allow tier downgrade mid-flow |
| Scope freezes prematurely | Medium | Medium | Two escape hatches (`-change` → addition/pivot); brainstorm sub-loop routes uncertainty to Open Questions, not silent freeze |
| Phase coverage blocks finalize indefinitely | Medium | Low | Allow `--force` with warning for exploratory scopes |
| Research agents hallucinate | Medium | Medium | Mandatory user review of SUMMARY.md; raw reports kept for audit |
| Brainstorm sub-loop runs away | Medium | Medium | Hard cap of 2 cycles per question; after 2 cycles, item routes to Open Questions |
| Authoritative ref bloats token budget per call | High | Medium | Load-mode policy (index_only/summarize) for large refs; cap total framing block at ~3k tokens; warn user if exceeded |
| User mislabels ref weight (authoritative vs. suggestive) | Medium | Medium | Weight is editable mid-flow; downgrading an authoritative ref triggers pivot classification (per §2) |
| Ref path goes stale between sessions | Medium | Low | On resume, validate each ref path exists; if missing, prompt user to re-link or downgrade to contextual |
| User invokes `/gabe-scope-change` but means pivot/addition imbalance | Medium | Medium | Classifier names rationale; user can `--force-pivot`/`--force-addition` |
| ROADMAP.md drifts from SCOPE.md | High | High | `/gabe-align` watchdog; `/gabe-commit` audit warns on direct edits |
| Re-invocation clobbers existing work | Low | Critical | "Start over" requires typed confirmation; tombstone archiving never deletes |
| Session resume across versions (command updated mid-session) | Low | Medium | session.json includes command version; mismatch forces fresh start with warning |

---

## 9. Open Questions — Resolved

| # | Question | Resolution |
|---|---|---|
| Q1 | Resume: same command or `/gabe-scope-resume`? | **Same command.** Bare `/gabe-scope` hits Step 0 re-invocation check, offers resume/start-fresh/abort. |
| Q2 | Does SCOPE.md participate in `/gabe-teach` learning patterns? | **Yes.** Cross-project patterns like "users keep revisiting Non-Goals at Step 5" feed `~/.claude/gabe-lens-learning.md`. |
| Q3 | Periodic "scope health check" (weekly / per-push)? | **No — delegated.** `/gabe-align`, `/gabe-review`, `/gabe-commit` each own drift detection in their domain. Not `/gabe-scope`'s job. |
| Q4 | Cross-project aggregation of common scope-time gaps? | **Yes.** Feeds gabe-lens-learning as suggested tailoring. |
| Q5 | Machine-readable change log (`CHANGES.jsonl`) alongside markdown? | **Yes.** Each change event writes both the markdown row and a JSONL entry for downstream tooling. |
| Q6 | Mid-flight abort cleanup? | **Tombstone.** `.kdbp/archive/tombstones/scope-session-{timestamp}.json`. Re-execution offers the Step 0 menu. |

---

## 10. What's NOT in this spec

- Implementation code — not yet.
- The actual prompts for each LLM call — drafted in the next spec pass.
- UI for the interview — assumed Claude Code CLI; no web UI.
- Multi-language support for the command itself — English only.
- Multi-tenant support — one user, one project per SCOPE.md.
- Versioning beyond major (v1, v2 after pivots) — no semver.

---

## 11. Next Step

Decisions are locked. Next drafts (in order of dependency):

1. **Prompts for the five Opus reasoning calls** (intake-quality evaluator, brainstorm analyst, success-criteria generator, REQ decomposer, phase skeleton + population) — these are the hardest parts and the ones that most determine command quality.
2. **SCOPE.md and ROADMAP.md template files** (actual markdown files under `templates/`).
3. **`/gabe-scope` command spec** — the `commands/gabe-scope.md` file, pattern-matched against `commands/gabe-teach.md` structure.
4. **`/gabe-scope-change` classifier spec** — smaller, depends on the pivot-trigger rules being formalized.
5. **`/gabe-scope-addition` and `/gabe-scope-pivot` specs** — inherit most machinery from `/gabe-scope`.
6. **Integration edits** — `/gabe-plan`, `/gabe-teach` (add SCOPE mode), `/gabe-align`, `/gabe-review`, `/gabe-commit`, `/gabe-push`.
