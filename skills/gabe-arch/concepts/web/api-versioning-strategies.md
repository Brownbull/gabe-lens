---
id: api-versioning-strategies
name: API Versioning Strategies
tier: intermediate
specialization: [web]
tags: [versioning, api, breaking-changes, semver]
prerequisites: [request-response-lifecycle]
related: [schema-evolution-expand-contract]
one_liner: "The day you ship v1 you've promised not to break it — plan for v2 before you need it."
---

## Analogy

A train station with multiple platforms running different timetables. Each platform is a version; new trains go to platform 2 without disrupting platform 1's passengers. You don't tear up platform 1 the day platform 2 opens — you run both until the last old train leaves.

## When it applies

- Public APIs with external clients you don't control
- Internal APIs with many consumers where coordinated deploys aren't feasible
- Mobile APIs where old client versions linger for years
- Any API that has shipped and has >0 real callers

## When it doesn't

- Internal APIs within a single deploy unit (just refactor)
- Pre-launch APIs where nothing is yet depending on them
- APIs where you control every consumer and can deploy atomically

## Primary force

A breaking change to an API in use breaks every client that hasn't upgraded. Versioning gives you a parallel track — old clients continue on v1 while new clients use v2, and you deprecate v1 on a schedule that gives consumers time to migrate. The main strategies (URL path `/v1/`, header `Accept: application/vnd.api.v2+json`, query param `?version=2`) all achieve the same goal; pick one and stick with it.

## Common mistakes

- Shipping v1 without a plan for breaking changes later
- Breaking v1 "just a little" and hoping nobody notices
- Supporting 5 versions forever (maintenance hell)
- Versioning the entire API when only one endpoint changed (use field-level evolution — see schema-evolution-expand-contract)
- No deprecation headers/dates communicated to clients

## Evidence a topic touches this

- Keywords: API version, /v1/, /v2/, Accept header, deprecation, breaking change
- Files: `**/api/v*`, `**/versioned*`, `**/routes/*`
- Commit verbs: "bump to v2", "deprecate v1", "add version path", "support both versions"

## Deeper reading

- Stripe API versioning (date-based version pinning)
- GitHub REST API v3 → v4 (REST → GraphQL) migration story
- "Designing Web APIs" (Jin, Sahni, Shevat) ch. 7
