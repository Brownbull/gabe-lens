# Scope Data Contracts

**Status:** Phase 2 freeze
**Related:** [gabe-scope-design.md](gabe-scope-design.md) · [gabe-scope-implementation-plan.md](gabe-scope-implementation-plan.md)

This doc is the authoritative contract between `/gabe-scope` (the producer) and the rest of the Gabe Suite (consumers). Every field produced by `/gabe-scope` is listed here with the step that writes it and the commands that read it. Changes here ripple to templates, schemas, prompts, and integration edits.

## Artifacts produced by `/gabe-scope`

| Artifact | Inertia | Writable by | Readable by |
|---|---|---|---|
| `.kdbp/SCOPE.md` | high | `/gabe-scope`, `/gabe-scope-pivot` | all gabe-* commands (read-only) |
| `.kdbp/ROADMAP.md` | medium | `/gabe-scope`, `/gabe-scope-addition`, `/gabe-scope-pivot` | all gabe-* commands (read-only) |
| `.kdbp/scope-references.yaml` | medium | `/gabe-scope`, `/gabe-scope-addition`, `/gabe-scope-pivot` | `/gabe-scope` family only |
| `.kdbp/scope-session.json` | transient | `/gabe-scope` | `/gabe-scope --resume` |
| `.kdbp/research/archive/*.md` | terminal | `/gabe-scope` Step 8 | `/gabe-scope-pivot` (regenerate on pivot) |
| `.kdbp/archive/tombstones/*.json` | terminal | `/gabe-scope` Step 0 start-over | none (audit only) |
| `.kdbp/CHANGES.jsonl` | append-only | `/gabe-scope` + `/gabe-scope-change` | downstream tooling (future) |

**Key invariant:** Only the `/gabe-scope` family writes to SCOPE.md and ROADMAP.md. `/gabe-commit` audit warns on direct edits. This is the cleanest architectural boundary.

## SCOPE.md fields — step-by-step production

| Section | Written at step | Read by | Stable anchor |
|---|---|---|---|
| Frontmatter: `name`, `created`, `project_kind` | Step 1 (intake) | all | — |
| Frontmatter: `version`, `last_scope_event`, `status` | Step 8 finalize, updated on any `-change` | all | — |
| Frontmatter: `primary_user` | Step 4 | `/gabe-teach` SCOPE mode | — |
| Frontmatter: `custom_sections` | Optional, user-set | `/gabe-scope`, `/gabe-scope-pivot` | — |
| §0 Reference Frame | Step 0.5 | `/gabe-scope` family only | `{#reference-frame}` |
| §1 One-liner | Step 3 | `/gabe-teach` SCOPE mode, `/gabe-align` | `{#one-liner}` |
| §2 Problem | Step 3 | `/gabe-teach` SCOPE mode | `{#problem}` |
| §3 Vision / North Star | Step 3 | `/gabe-teach` SCOPE mode | `{#vision}` |
| §4 Primary User & JTBD | Step 4 | `/gabe-teach`, `/gabe-align` | `{#primary-user}` |
| §5 Secondary Users (optional) | Step 4 | `/gabe-teach` | `{#secondary-users}` |
| §6 Non-Users | Step 4 | `/gabe-teach`, `/gabe-align` drift detection | `{#non-users}` |
| §7 Success Criteria (SC-NN) | Step 5 | `/gabe-plan`, `/gabe-teach`, `/gabe-align` | `{#success-criteria}`, per-SC `{#sc-NN}` |
| §8 Non-Goals (NG-NN) | Step 5 | `/gabe-align` (drift detection) | `{#non-goals}` |
| §9 Constraints | Step 6 | `/gabe-plan`, `/gabe-align` | `{#constraints}` |
| §10 Architecture Posture | Step 6 | `/gabe-plan`, `/gabe-teach` ARCH mode | `{#architecture-posture}` |
| Custom sections (if any) | Step 6 | varies | user-defined |
| §12 Requirements (REQ-NN) | Step 7.1 | `/gabe-plan`, `/gabe-teach` SCOPE mode | `{#requirements}`, per-REQ `{#req-NN}` |
| §13 Strategic Risks | Step 7.1 | `/gabe-plan`, `/gabe-align` | `{#strategic-risks}` |
| §14 Open Questions | All steps (brainstorm exits + user-deferred) | `/gabe-teach` | `{#open-questions}` |
| §15 Change Log | Step 8 + all `-change` events | auditors | `{#change-log}` |

### Stable anchor conventions

| Element | Anchor format | Example |
|---|---|---|
| Named section | `{#kebab-case}` | `{#success-criteria}` |
| Success Criterion | `{#sc-NN}` | `{#sc-01}` |
| Requirement | `{#req-NN}` | `{#req-01}` |
| Non-Goal | `{#ng-NN}` | `{#ng-01}` |
| Strategic Risk | `{#sr-NN}` | `{#sr-01}` |
| Open Question | `{#oq-NN}` | `{#oq-01}` |
| Phase (in ROADMAP.md) | `{#phase-N}` or `{#phase-N-M}` for decimal | `{#phase-3}`, `{#phase-3-1}` |

Anchors are mandatory. `/gabe-plan` and `/gabe-teach` deep-link to them; missing anchors break downstream commands.

## ROADMAP.md fields — step-by-step production

| Section | Written at step | Read by | Stable anchor |
|---|---|---|---|
| Frontmatter: `scope_file`, `scope_version` | Step 8 | all | — |
| Frontmatter: `roadmap_version` | Step 8 + all `-change` | all | — |
| Frontmatter: `granularity` | Step 7.2 | `/gabe-scope-addition` (when inserting phases) | — |
| Frontmatter: `phases_total`, `phases_complete` | Step 8, updated by `/gabe-align` | `/gabe-plan`, `/gabe-teach` | — |
| §1 Granularity | Step 7.2 | docs only | — |
| §2 Phase Table (at a glance) | Step 7.3 skeleton, Step 7.4 populate | `/gabe-plan` (primary), `/gabe-teach`, `/gabe-align` | — |
| §3 Phase Detail (per phase) | Step 7.3 + Step 7.4 | `/gabe-plan`, `/gabe-teach` SCOPE mode | `{#phase-N}` per phase |
| §4 Dependency Graph (Mermaid) | Step 8 auto-gen | docs only | — |
| §5 Coverage Matrix | Step 7.4 | `/gabe-scope` finalize blocker, `/gabe-align` drift | — |
| §6 Roadmap Change Log | Step 8 + all `-change` | auditors | — |

### Phase-row required columns (for /gabe-plan consumption)

| Column | Type | Purpose |
|---|---|---|
| ID | integer or `N.M` | Phase identifier; decimal = `-addition` insert |
| Name | string | Human-readable name |
| Status | enum: `pending | in-progress | blocked | complete | deferred` | Lifecycle state |
| Depends-on | list of IDs | Prerequisite phases |
| Parallel-with | list of IDs | Can run concurrently |
| Covers REQs | list of markdown links `[REQ-NN](SCOPE.md#req-NN)` | Traceability |

### Phase-detail required fields

| Field | Type | Read by |
|---|---|---|
| Name, Status | — | `/gabe-plan` |
| Goal (observable user truth) | paragraph | `/gabe-plan`, `/gabe-teach` |
| **Why (business intent)** | paragraph | **`/gabe-teach` SCOPE mode** (high-value unlock per read-needs review) |
| Covers REQs | list of markdown links | `/gabe-plan`, `/gabe-align` |
| Depends-on, Parallel-with | list | `/gabe-plan` |
| Exit criteria | bullet list | `/gabe-align` drift detection |

## scope-references.yaml contract

See [schemas/scope-references.schema.json](../schemas/scope-references.schema.json) for the full JSON Schema (YAML maps to same shape).

Key rules:
- `id` is stable (never reused after removal)
- `weight` downgrade (authoritative → suggestive, suggestive → contextual) triggers pivot classification in `/gabe-scope-change`
- `load_mode: summarize` requires `summary` + `summary_cached_at`
- Empty `references: []` is valid — indicates no-framing mode

## scope-session.json contract

See [schemas/scope-session.schema.json](../schemas/scope-session.schema.json) for the full JSON Schema.

Key rules:
- `command_version` must match current `/gabe-scope` version on resume; mismatch forces fresh start
- `current_step` is the step paused at; `completed_steps` tracks what's approved behind it
- `prompt_versions_used` captures every prompt version called; session is incompatible with future versions
- `brainstorm_cycles` capped at 2 per question (enforced by prompt + command)
- `follow_ups_asked` capped at 10 per session (interview depth limit per design §4 Step 1)
- `coverage_status.blocks_finalize=true` blocks Step 8 unless `force_override=true`

## Downstream command read-needs (from Phase 2 review)

Recorded here to prevent Phase 7 rework (mitigation for IR9).

### `/gabe-plan`

- Reads ROADMAP.md phase rows to find phase by ID
- Reads per-phase Goal + Exit criteria + Covers REQs
- Reads SCOPE.md REQ-NN blocks (by anchor) to get REQ text + acceptance signal
- Reads SCOPE.md Constraints + Architecture Posture for context
- Does NOT write to SCOPE.md or ROADMAP.md

### `/gabe-align`

- Reads ROADMAP.md phase status + exit criteria to detect drift
- Reads SCOPE.md Success Criteria + Non-Goals to flag code that implements outside scope
- Reads per-phase Covers REQs to verify shipped code satisfies declared coverage
- Does NOT write to SCOPE.md or ROADMAP.md

### `/gabe-teach` (SCOPE mode, new in Phase 7)

- Reads SCOPE.md §1–10 for premise teaching
- Reads SCOPE.md Requirements for "why this REQ exists" lessons
- Reads ROADMAP.md per-phase **Why (business intent)** paragraphs — highest-value read
- Reads ROADMAP.md Phase Detail sections via `{#phase-N}` anchors for deep lesson links
- Does NOT write to SCOPE.md or ROADMAP.md

### `/gabe-review`, `/gabe-commit`, `/gabe-push`, `/gabe-init` (minor)

- `/gabe-commit`: warns if a commit modifies SCOPE.md or ROADMAP.md directly (bypass of `/gabe-scope-change`)
- `/gabe-push`: optional `phase_id` tag in DEPLOYMENTS.md for traceability
- `/gabe-review`, `/gabe-init`: no current SCOPE/ROADMAP reads

## Anchor stability guarantees

Once a REQ/SC/Phase anchor is published (i.e., present in a finalized SCOPE.md or ROADMAP.md), it is **immutable** even if the entity is renamed or removed:

- **Rename** — display name changes; anchor stays. Example: REQ-03 "Ambient surfacing" → "Smart recall" keeps `{#req-03}`.
- **Remove via `-addition`** — not allowed. REQs can only be removed via `-pivot` which archives the whole document to `vN`.
- **Remove via `-pivot`** — anchor is retired. New `vN+1` document gets fresh anchor space but may reuse IDs from `vN` (the archive preserves the history).

Downstream tools that deep-link to anchors should ALSO record which SCOPE.md version they linked against, so they can detect post-pivot staleness.

## Versioning

| Artifact | Version bump trigger | Where recorded |
|---|---|---|
| SCOPE.md | `/gabe-scope-pivot` only | Frontmatter `version:` |
| ROADMAP.md | Any `/gabe-scope-change` (addition OR pivot) | Frontmatter `roadmap_version:` |
| scope-references.yaml | Any add/remove/weight-change | No explicit version; Change Log in SCOPE.md tracks |
| Prompts (`prompts/*.md`) | Semantic change | Frontmatter `version:` |

Mismatch between `scope_version:` in ROADMAP.md and `version:` in SCOPE.md is a hard error — ROADMAP must regenerate on SCOPE.md pivot.
