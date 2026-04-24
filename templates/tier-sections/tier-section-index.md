# Tier Section Catalog Index

Maps phase trigger tags to section files. `/gabe-plan` reads this to assemble the tier trade-off matrix for each phase.

## Section catalog (v2 — 20 sections)

| Section              | File                       | Trigger tags                        | Purpose                                           |
|----------------------|----------------------------|-------------------------------------|---------------------------------------------------|
| Core                 | core.md                    | always                              | Testing, error-handling, observability, abstrax  |
| Data                 | data.md                    | data-migration, persistence         | Server-side persistence + schema                  |
| Multi-tenant         | multi-tenant.md            | multi-tenant, org-scoped            | Tenant isolation, RBAC, audit                     |
| AI/Agent             | ai-agent.md                | ai-agent, llm                       | LLM orchestration, eval, structured output        |
| UI/UX                | ui-ux.md                   | user-facing                         | Rendering, a11y, streaming feedback               |
| Integration          | integration.md             | external-api                        | Retry, idempotency, rate-limit                    |
| Compute              | compute.md                 | perf-sensitive                      | Server caching, batching, pooling                 |
| Client State         | client-state.md            | client-state, spa, pwa              | Client cache, invalidation, cross-tab sync        |
| Auth/Session         | auth-session.md            | auth, session                       | Token refresh, CSRF, session lifecycle            |
| Background jobs      | background-jobs.md         | async-worker, queue                 | Queue retry, DLQ, idempotency (job-level)         |
| Real-time            | real-time.md               | realtime, streaming, sse            | Reconnection, backpressure, presence              |
| Deployment/Release   | deployment-release.md      | migration, rollout                  | Feature flags, canary, rollback safety            |
| File/Media           | file-media.md              | upload, storage, cdn                | Upload, virus scan, CDN, retention                |
| Notifications        | notifications.md           | email, push, sms                    | Delivery, preferences, templating, tracking       |
| Design System        | design-system.md           | design-system                       | Tokens, type scale, spacing, motion               |
| UI Kit               | ui-kit.md                  | ui-kit                              | Atomic + molecular inventory, state matrix        |
| Flows                | flows.md                   | mockup-flows                        | User-flow enumeration + walkthroughs              |
| Mockup Index         | index-mockup.md            | mockup-index                        | INDEX.md governance, CRUD×entity, coverage        |
| Mockup Docs          | documentation-mockup.md    | mockup-docs                         | HANDOFF schema, SCREEN-SPECS, a11y audit          |
| Mockup Validation    | validation-mockup.md       | mockup-validation                   | REQ×screen, token parity, WCAG AA pass            |

### Mockup-tag set (dispatch detection)

Used by `/gabe-mockup` / `/gabe-execute` / `/gabe-next` to detect mockup phases in hybrid plans:

```
{design-system, ui-kit, mockup-flows, mockup-index, mockup-docs, mockup-validation}
```

Primary dispatch is by `project_type` frontmatter field in `PLAN.md` (`mockup | code | hybrid`). Per-phase type detection is a fallback for hybrid plans.

## Assembly rules

1. **Layer 1 — Section-by-tag.** Phase's `types: [...]` list picks which sections render. Core ALWAYS renders.
2. **Layer 2 — Dimension-by-LLM.** Within each rendered section, LLM pre-filters rows per phase task breakdown. Suppressed rows logged to DECISIONS.md with reason.
3. **Layer 3 — Core always full.** Core's 4 dimensions never filtered. Non-negotiable.
4. **`--full-catalog` flag** overrides Layer 2. All dimensions of all matched sections render.

## Column widths (strict)

Every section file obeys 110-char row budget with 6 columns:

| Column     | Width | Padding rule |
|------------|-------|--------------|
| Dimension  | 20    | left-align, space-pad right |
| MVP        | 20    | terse option, abbreviate if needed |
| Δ(M→E)     | 6     | S / M / L / XL, left-align |
| Enterprise | 20    | terse option |
| Δ(E→S)     | 6     | S / M / L / XL |
| Scale      | 19    | terse option (19 cap to land exact 110) |

Total row width = 110 chars (content 90 + pipes/padding 20).

**Additive shorthand:** `+` prefix in Ent/Scale columns = "adds on top of prior tier." Saves width, preserves tier semantics.

## Deferred sections (post-v1)

Land as files in this directory when first needed:

- Security/Secrets — PII, encryption, compliance
- Search/Retrieval — full-text, vector search, rerank
- Analytics/Product telemetry — event tracking, funnels
- i18n/Localization — language, timezone, currency

## See also

- `tier-delta-scale.md` — S/M/L/XL rubric + prototype-tag shift
- `/gabe-plan` — assembly orchestrator
- `/gabe-execute` — tier-cap enforcement
- `/gabe-review` — TIER_DRIFT finding class
