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

## Analogy

Your house key on your keyring vs. taped to the front door for convenience. One is a key; the other is an invitation. Committed credentials are the invitation — once they're in git history, they're reachable by anyone who ever gets read access, forever.

## When it applies

- Every project from day one
- API keys, database passwords, JWT secrets, webhook signing keys
- Third-party service credentials (payment providers, email, cloud)
- OAuth client secrets, encryption keys, TLS certificates
- Literally any string your system treats as sensitive

## When it doesn't

- Public keys (asymmetric crypto) — those are meant to be shared
- Non-sensitive config (feature flags, public URLs, log levels)
- Intentionally public "test" credentials for sandboxes (document them as such)

## Primary force

Committed secrets leak. Git history never forgets — removing the secret from the current tree doesn't remove it from history, and forks/clones preserve the entire history. Standard remediation requires rotating the credential everywhere it's used; often that takes days and causes outages. Env vars, secret managers (Vault, AWS Secrets Manager, Doppler), and `.env` files (gitignored) keep secrets out of the repo entirely. Once leaked, always leaked.

## Common mistakes

- Committing `.env` "just this one time, I'll remove it later" (git history preserves it)
- Logging request headers that contain tokens (your logs are now a secret store)
- Rotating a leaked credential without auditing what used it (you miss some consumer)
- Environment variables set in CI configs committed to the repo (same leak, different file)
- Hardcoded fallback values "for local dev" that are also production credentials

## Evidence a topic touches this

- Keywords: .env, secrets, API key, credentials, vault, dotenv, SECRET_KEY
- Files: `.env*`, `**/config*`, `**/secrets*`, `docker-compose.yml`
- Commit verbs: "add API key", "load from env", "rotate credential", "fix leaked secret"

## Deeper reading

- OWASP Cheat Sheet: Secrets Management
- The Twelve-Factor App (Factor III: Config)
- `git-secrets`, `trufflehog`, `gitleaks` — scanning tools
