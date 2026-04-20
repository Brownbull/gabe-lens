---
id: secrets-via-env-never-code
name: Secrets via Env, Never in Code
tier: foundational
specialization: [security]
tags: [secrets, env-vars, credentials, leakage]
prerequisites: []
related: [input-validation-at-boundary]
one_liner: "Credentials go in environment variables or a secret manager — never in git, ever."
---

## The problem

An API key committed "just for testing" lives forever in git history. Removing it from the current tree doesn't remove it from past commits, and every fork, clone, and CI cache still has it. Rotating that key means finding every consumer, pushing coordinated updates, and often an outage.

## The idea

Secrets live in environment variables or a dedicated secret manager, loaded at runtime — source files never contain credentials, ever, not even temporarily.

## Picture it

Your house key on a keyring in your pocket versus that same key taped to the front door for convenience. One is a key. The other is an invitation. A committed credential is the taped key — once anyone walks by, it's theirs forever.

## How it maps

```
House key in pocket       →  secret in process env or secret manager
Key taped to door         →  credential string checked into source
The street outside        →  the public internet, plus every fork of your repo
Every passerby            →  anyone with repo read access, now or ever
Rekeying the entire lock  →  rotating the credential everywhere it's used
Keyring away from door    →  .env file gitignored, loaded at process start
Lockbox at bank           →  secret manager (Vault, AWS Secrets Manager, Doppler)
```

## Primary force

Committed secrets leak — git history never forgets, and forks/clones preserve the entire history. Remediation means rotating the credential everywhere it's used, which often takes days and causes outages. Env vars, secret managers, and gitignored `.env` files keep the secret out of the repo entirely, making rotation a config change instead of a fire drill. Once leaked, always leaked; the only safe credential is one that never entered the repo.

## When to reach for it

- Every project from day one — API keys, DB passwords, JWT signing secrets, webhook keys.
- Third-party service credentials — payment providers, email, cloud, OAuth client secrets.
- Any string your system treats as sensitive — encryption keys, TLS certs, signing material.

## When NOT to reach for it

- Public keys for asymmetric crypto — those are meant to be shared.
- Non-sensitive config (feature flags, public URLs, log levels) — env is fine but not required.
- Intentionally public "sandbox" test credentials — document them as such, don't hide them.
- Hardcoded fallback values "for local dev" that match production credentials — same leak.

## Evidence a topic touches this

- Keywords: .env, secrets, API key, credentials, vault, dotenv, SECRET_KEY
- Files: `.env*`, `**/config*`, `**/secrets*`, `docker-compose.yml`
- Commit verbs: "add API key", "load from env", "rotate credential", "fix leaked secret"

## Deeper reading

- OWASP Cheat Sheet: Secrets Management
- The Twelve-Factor App (Factor III: Config)
- `git-secrets`, `trufflehog`, `gitleaks` — scanning tools
