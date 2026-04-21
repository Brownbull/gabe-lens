---
name: <project name>
version: 1
status: active
created: <YYYY-MM-DD>
last_scope_event: <YYYY-MM-DD>
primary_user: <one-liner>
project_kind: agent-app | web-app | cli | library | other
custom_sections: []
roadmap_file: .kdbp/ROADMAP.md
reference_frame_file: .kdbp/scope-references.yaml
---

# SCOPE — <project name>

> **This is the stable backbone.** Changes to this document flow exclusively through `/gabe-scope-change` (which routes to `/gabe-scope-addition` or `/gabe-scope-pivot`). Direct edits are flagged by `/gabe-commit` audit.

## 0. Reference Frame {#reference-frame}

<!-- Populated from .kdbp/scope-references.yaml. Omit this section entirely if no references are declared. -->

The following external documents framed this scoping. See `.kdbp/scope-references.yaml` for full entries.

| ID | Weight | Path | Role |
|---|---|---|---|
| ref-01 | authoritative | <path> | <one-line role> |
| ref-02 | suggestive | <path> | <one-line role> |
| ref-03 | contextual | <path> | <one-line role> |

**Conflict resolution:** Authoritative refs are hard constraints; any deviation is recorded in the Change Log below. Downgrading an authoritative ref triggers a pivot.

## 1. One-liner {#one-liner}

<The pitch in ≤25 words.>

## 2. Problem {#problem}

<What pain this solves, who feels it, evidence it matters. 3–5 paragraphs or bullets.>

## 3. Vision / North Star {#vision}

<Where this goes in 1–3 years if everything works.>

## 4. Primary User & Jobs-to-be-Done {#primary-user}

**Primary user:** <role / persona>

**Jobs-to-be-Done:**
- **When I** <context>, **I want to** <action>, **so I can** <outcome>.
- **When I** <context>, **I want to** <action>, **so I can** <outcome>.

## 5. Secondary Users {#secondary-users}

<Optional. Others who benefit; explicitly ranked below primary. Omit section if none.>

- **<Role>** — <how they benefit, why secondary>

## 6. Non-Users {#non-users}

<Explicitly NOT for these people. Mandatory — cannot be empty.>

- **<Role / segment>** — <why not for them>
- **<Role / segment>** — <why not for them>

## 7. Success Criteria {#success-criteria}

Goal-backward, observable user truths. Every criterion below is covered by ≥1 Requirement in §12.

- **SC-01** {#sc-01} — A user can <observable action> within <constraint>.
- **SC-02** {#sc-02} — A user can <observable action> within <constraint>.
- **SC-03** {#sc-03} — <...>

## 8. Non-Goals {#non-goals}

What we are explicitly NOT building, each paired with why.

- **NG-01** — <what we're not building>. **Why:** <rationale>.
- **NG-02** — <what we're not building>. **Why:** <rationale>.

## 9. Constraints {#constraints}

| Dimension | Constraint |
|---|---|
| Tech stack | <committed stack> |
| Budget | <monetary / token / compute> |
| Timeline | <milestone dates if fixed> |
| Regulatory | <compliance requirements> |
| Team size | <people / roles> |
| Infra | <deployment / runtime limits> |

## 10. Architecture Posture {#architecture-posture}

High-level shape only — detailed module design lives in per-phase PLAN.md files.

- **Synchrony:** <sync | async-first | mixed>
- **Topology:** <monolith | multi-agent | microservices | library>
- **Data gravity:** <local-first | cloud-first | hybrid>
- **Deployment target:** <where it runs>
- **Integration surface:** <key external APIs / systems>

<!-- ===== Custom sections (optional, per custom_sections: frontmatter) ===== -->
<!-- Custom sections appear here, between Architecture Posture and Requirements. -->

## 12. Requirements {#requirements}

Each requirement covers one or more Success Criteria. Every requirement maps to exactly one Phase in [ROADMAP.md](ROADMAP.md).

### REQ-01 — <short name> {#req-01}
**Covers SCs:** [SC-01](#sc-01)
**Description:** <concrete requirement statement>
**Acceptance signal:** <how we know it's done>

### REQ-02 — <short name> {#req-02}
**Covers SCs:** [SC-01](#sc-01), [SC-02](#sc-02)
**Description:** <...>
**Acceptance signal:** <...>

<!-- Add REQ blocks as needed. Each must have a unique REQ-NN ID + {#req-NN} anchor. -->

### Coverage matrix (auto-generated)

| Success Criterion | Covered by REQs |
|---|---|
| SC-01 | REQ-01, REQ-02 |
| SC-02 | REQ-02 |
| SC-03 | REQ-03 |

Every SC must have ≥1 REQ. Finalize blocks if the matrix is incomplete.

## 13. Strategic Risks {#strategic-risks}

Premise-level risks only. Implementation risks live in per-phase PLAN.md files.

| # | Risk | Likelihood | Severity | Mitigation posture |
|---|---|---|---|---|
| SR-01 | <risk statement> | Low/Med/High | Low/Med/High | <stance, not tactics> |

## 14. Open Questions {#open-questions}

Unresolved items from scoping. Items marked `[UNRESOLVED — brainstorm exit]` came from the §3.5 sub-loop hitting its 2-cycle cap.

- **OQ-01** — <question>. **Status:** open.
- **OQ-02** — <question>. **Status:** `[UNRESOLVED — brainstorm exit]`.

## 15. Change Log {#change-log}

Append-only. Each entry: date, type (`init | addition | pivot`), summary, diff pointer (optional).

| Date | Type | Summary |
|---|---|---|
| <YYYY-MM-DD> | init | Initial scope authored via `/gabe-scope`. |
