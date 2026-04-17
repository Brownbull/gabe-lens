---
id: authn-vs-authz
name: "Authentication vs Authorization (Authn vs Authz)"
tier: foundational
specialization: [security]
tags: [authn, authz, identity, permissions, rbac]
prerequisites: []
related: [input-validation-at-boundary]
one_liner: "Authn proves who you are; authz decides what you're allowed to do — two problems, two layers."
---

## Analogy

Authentication = the bouncer checking your ID at the nightclub door ("yes, you're Alex"). Authorization = the VIP rope inside ("Alex is allowed in the main room but not the VIP lounge"). Same person, two separate decisions, made by different systems for different reasons.

## When it applies

- Any multi-user system (literally every one)
- APIs that distinguish between users or roles
- Systems with admin/user/guest tiers
- Services accessing downstream resources on behalf of a user (delegation)

## When it doesn't

- Single-user local scripts
- Systems where every caller has identical permissions (rare; often masks a future requirement)
- Pre-auth health check endpoints (but those should be explicitly marked)

## Primary force

Conflating identity and permissions is a top source of production security bugs. Authn happens once per request (or once per session), using standards like OAuth, JWT, or session cookies. Authz happens on every resource access, using role checks, policy engines, or ACLs. Keeping them in separate layers means you can change how users log in (SSO rollout, password policy) without touching permissions, and you can refactor permissions (RBAC → ABAC) without re-authenticating users.

## Common mistakes

- Using "authentication" to decide what a user can do ("if logged in, allowed" — misses per-resource checks)
- Role checks scattered throughout handlers instead of centralized policy
- Admin endpoints protected only by obscurity (`/admin-panel-9a8f`)
- Trusting client-supplied user IDs in a request (use the authenticated session, not a body field)
- JWT payload trusted as authoritative (anyone can forge a JWT; you verify signature AND re-fetch authoritative data)

## Evidence a topic touches this

- Keywords: authn, authz, authorization, permissions, RBAC, role, JWT, OAuth
- Files: `**/auth*`, `**/middleware*`, `**/permissions*`, `**/policies*`
- Commit verbs: "add auth check", "require role", "authorize", "verify JWT"

## Deeper reading

- OWASP ASVS: Authentication (V2), Access Control (V4)
- "The Three Rs of Authorization" — Okta Engineering
- OAuth 2.0 / OIDC specs
