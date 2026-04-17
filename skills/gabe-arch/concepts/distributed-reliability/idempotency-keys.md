---
id: idempotency-keys
name: Idempotency Keys
tier: foundational
specialization: [distributed-reliability]
tags: [idempotency, retry-safety, deduplication, stripe-pattern]
prerequisites: []
related: [retry-with-exponential-backoff, async-background-processing]
one_liner: "Tag each write so replays don't double-charge — the price of retry-safety."
---

## Analogy

A concert ticket with a unique serial number. Scan it once — enter. Scan it again — already used, bounced. The door doesn't let the same person in twice, no matter how many times they try the same ticket.

## When it applies

- Every non-read API endpoint (POST, PUT, PATCH, DELETE) facing unreliable networks
- Payment systems, order placement, any write where duplicates cost money
- Webhook receivers (providers routinely re-deliver)
- Background job enqueue operations
- Any system where retries are allowed

## When it doesn't

- Pure read operations (inherently idempotent)
- Write operations where duplicates are harmless and cheap (rare — usually a false belief)
- Systems where you've built a full distributed transaction log instead (e.g., event sourcing)

## Primary force

Retries are necessary. Duplicates from retries are catastrophic. Idempotency keys let the server recognize "I saw this exact request already" and return the original response rather than processing a second time. The caller generates a UUID per logical operation, server stores {key: response} for a retention window, replays are safe. Without this, retry logic is a bug waiting to happen.

## Common mistakes

- Using the request body hash as the key (collisions when two different users happen to submit the same content)
- No TTL on the key store (unbounded growth)
- Keys scoped globally when they should be per-user (privacy leak)
- Client generates the key but forgets to send it on retry (treated as new request)
- Server stores success response but not errors — retry of a legitimately-failed request succeeds the second time through a bug

## Evidence a topic touches this

- Keywords: idempotency key, Idempotency-Key header, deduplicate, once-and-only-once, Stripe-style
- Files: `**/api/*.py`, `**/middleware*`, `**/idempotency*`
- Commit verbs: "add idempotency", "dedupe by key", "accept X-Idempotency-Key"

## Deeper reading

- Stripe API docs — the canonical implementation
- IETF draft: "The Idempotency-Key HTTP Header Field"
