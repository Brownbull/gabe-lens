---
name: bookmark-manager
version: 1
status: active
created: 2026-04-21
last_scope_event: 2026-04-21
primary_user: solo knowledge workers who accumulate 500+ bookmarks
project_kind: web-app
custom_sections: []
roadmap_file: .kdbp/ROADMAP.md
reference_frame_file: .kdbp/scope-references.yaml
---

# SCOPE — bookmark-manager

> **This is the stable backbone.** Changes to this document flow exclusively through `/gabe-scope-change`.

## 0. Reference Frame {#reference-frame}

| ID | Weight | Path | Role |
|---|---|---|---|
| ref-01 | authoritative | ~/.claude/rules/common/coding-style.md | Coding style we follow |
| ref-02 | suggestive | ./docs/wireframes/ | UX direction from prior sprint |

## 1. One-liner {#one-liner}

A local-first bookmark manager that surfaces what you actually need when you need it, without you having to remember you saved it.

## 2. Problem {#problem}

Knowledge workers accumulate hundreds of bookmarks across browsers, read-later apps, and note-taking tools. The bookmark is saved; the intent behind saving it is lost. When the need returns, you either can't find it ("was it Pocket or Raindrop?") or don't remember you saved it at all.

Evidence: personal experience across 3 browsers × 5 years × ~1,200 bookmarks. Informal surveys in two Discord servers show ~40% of members routinely re-find content they've already saved.

## 3. Vision / North Star {#vision}

In 1–3 years: an ambient tool that watches what you're working on and surfaces the bookmark you saved eight months ago that's suddenly relevant again — before you ask.

## 4. Primary User & Jobs-to-be-Done {#primary-user}

**Primary user:** Solo knowledge workers (developers, researchers, writers) who save 100+ links per year and routinely re-search for content they've already bookmarked.

**Jobs-to-be-Done:**
- **When I** save a link while reading, **I want to** add context (why I care) in one keystroke, **so I can** understand my past intent later.
- **When I** return to a topic after weeks, **I want to** see all my saved material about it without remembering I saved it, **so I can** build on prior research instead of starting over.

## 5. Secondary Users {#secondary-users}

- **Small teams (≤5 people)** — could share a common knowledge pool. Ranked below primary because the single-user experience must dominate design decisions.

## 6. Non-Users {#non-users}

- **Enterprise teams (>50 people)** — shared taxonomy management, access controls, and audit trails are explicitly out of scope.
- **Casual bookmarkers (<50 links/year)** — the tool's value hinges on re-find friction, which casual users don't feel.
- **Users who want a social / discovery feed** — this is not a Twitter-alternative or a Pinboard clone.

## 7. Success Criteria {#success-criteria}

- **SC-01** {#sc-01} — A user can save a link with context in ≤3 seconds from clipboard.
- **SC-02** {#sc-02} — A user can re-find a bookmark by approximate topic in ≤30 seconds without remembering the exact title or URL.
- **SC-03** {#sc-03} — A user can see surfaced-to-them bookmarks when opening the app, without querying.

## 8. Non-Goals {#non-goals}

- **NG-01** — Multi-user sync beyond a single person's devices. **Why:** Collaboration features would dominate scope and dilute the ambient-surfacing focus.
- **NG-02** — Mobile-first experience. **Why:** Re-find friction is dominant on desktop; mobile-first would force UX compromises that hurt the core use case.
- **NG-03** — Paid SaaS with hosted sync. **Why:** Local-first is an architecture commitment, not a feature toggle.

## 9. Constraints {#constraints}

| Dimension | Constraint |
|---|---|
| Tech stack | Tauri + React + SQLite (local) per ref-01 |
| Budget | $0 infra (local-first); token budget ≤ $20/mo for AI surfacing |
| Timeline | v1 shipped to self by end of Q2 |
| Regulatory | GDPR-trivial (no PII leaves device) |
| Team size | 1 (solo project) |
| Infra | Desktop binaries for macOS + Linux |

## 10. Architecture Posture {#architecture-posture}

- **Synchrony:** async-first for AI surfacing, sync for CRUD
- **Topology:** single-binary desktop app
- **Data gravity:** local-first (SQLite); no cloud
- **Deployment target:** user's laptop
- **Integration surface:** browser extensions (Chrome, Firefox) + optional clipboard watcher

## 12. Requirements {#requirements}

### REQ-01 — Clipboard quick-save {#req-01}
**Covers SCs:** [SC-01](#sc-01)
**Description:** Global hotkey captures URL from clipboard + prompts for one-line context. Saved in ≤3s.
**Acceptance signal:** Benchmark: 10 saves averaged; p95 ≤ 3s from hotkey to stored record.

### REQ-02 — Semantic re-find {#req-02}
**Covers SCs:** [SC-02](#sc-02)
**Description:** Search by approximate topic (embedding-based). No exact-string requirement.
**Acceptance signal:** User test: find a bookmark saved 60+ days ago using only topic recall; ≤30s.

### REQ-03 — Ambient surfacing {#req-03}
**Covers SCs:** [SC-03](#sc-03)
**Description:** On app open, surface 3–5 bookmarks the user is likely to find useful right now, based on recent browser history + calendar context.
**Acceptance signal:** User reports ≥1 surprise-useful surfacing per week for 4 weeks.

### Coverage matrix (auto-generated)

| Success Criterion | Covered by REQs |
|---|---|
| SC-01 | REQ-01 |
| SC-02 | REQ-02 |
| SC-03 | REQ-03 |

## 13. Strategic Risks {#strategic-risks}

| # | Risk | Likelihood | Severity | Mitigation posture |
|---|---|---|---|---|
| SR-01 | Ambient surfacing feels creepy or useless | Medium | High | Ship REQ-03 behind a feature flag; validate with self for 4 weeks before promoting |
| SR-02 | Embedding model costs exceed $20/mo | Low | Medium | Use local embedding model (sentence-transformers); only call Claude for explanation, not embedding |
| SR-03 | Data loss from local-only storage | Medium | High | Document export + auto-backup to Dropbox/iCloud folder as user opt-in |

## 14. Open Questions {#open-questions}

- **OQ-01** — Browser extension security model — content script permissions vs. native messaging? **Status:** open; defer until Phase 3.
- **OQ-02** — Calendar integration scope — macOS only, or also Google Calendar? **Status:** `[UNRESOLVED — brainstorm exit]`.

## 15. Change Log {#change-log}

| Date | Type | Summary |
|---|---|---|
| 2026-04-21 | init | Initial scope authored via `/gabe-scope`. |
