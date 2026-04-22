# Section: Background jobs

**Trigger tags:** `async-worker`, `queue`

**Purpose:** Async job posture. Applies to phases that enqueue work for later processing (Celery, RQ, Sidekiq, Bull, SQS, Cloud Tasks, custom workers).

## Dimensions (5)

| Dimension            | MVP                  | Δ(M→E) | Enterprise           | Δ(E→S) | Scale               |
|----------------------|----------------------|--------|----------------------|--------|---------------------|
| Retry policy         | none                 | L      | N retries            | M      | + exp backoff       |
| Dead-letter          | drop                 | XL     | log + alert          | M      | + DLQ + replay UI   |
| Idempotency          | assume once          | XL     | job ID dedupe        | M      | + side-effect keys  |
| Scheduling           | now only             | M      | cron basic           | S      | + distrib + jitter  |
| Concurrency          | unbounded            | L      | fixed workers        | M      | + adaptive priority |

## Notes

- **Retry policy:** MVP = job fails, stays failed, user notified never. Enterprise = N retries with linear delay. Scale = exponential backoff + retry budget.
- **Dead-letter:** XL skip MVP→Ent. `drop` = silent data loss on failure. Enterprise = log + alert on terminal failure. Scale = dedicated DLQ with replay UI for ops to investigate + requeue.
- **Idempotency:** XL skip MVP→Ent. Jobs must be safe to re-execute. MVP "assume once" = duplicate side effects on retry. Enterprise = job-ID-based dedupe at worker. Scale = side-effect-key dedupe (detect duplicate *effects* not just duplicate *jobs*).
- **Scheduling:** MVP = jobs enqueue immediately. Enterprise = basic cron scheduling. Scale = distributed scheduler with jitter (prevent thundering herd on periodic jobs).
- **Concurrency:** MVP = every enqueued job runs immediately (unbounded worker spawn). Enterprise = fixed pool size. Scale = adaptive concurrency with priority queues.

## Tier-cap enforcement

- **MVP phase:** `@task(retry_policy=...)`, DLQ queue configuration, `exp_backoff` imports trigger escalation.
- **Enterprise phase:** priority queue config, replay UI scaffolding trigger Scale escalation.

## Known drift signals

| Pattern                                           | Tier floor | Finding severity |
|---------------------------------------------------|------------|------------------|
| Celery `autoretry_for=...` / Sidekiq `sidekiq_retry_in` | Enterprise | TIER_DRIFT-MED |
| Dead-letter queue binding (SQS DLQ, Sidekiq dead set) | Enterprise | TIER_DRIFT-MED |
| Job-ID idempotency key on worker                  | Enterprise | TIER_DRIFT-MED   |
| Side-effect-key dedupe (Redis SET NX w/ TTL per effect) | Scale | TIER_DRIFT-HIGH |
| Priority queue w/ weighted routing                | Scale      | TIER_DRIFT-MED   |
| Adaptive concurrency controller                   | Scale      | TIER_DRIFT-HIGH  |
| Distributed cron (`celery-beat` + redbeat, k8s CronJob) | Scale | TIER_DRIFT-LOW |

## Red-line items

- **Idempotency on money/comms jobs.** Any phase enqueueing jobs that charge cards, send emails, create accounts, or trigger external mutations MUST declare Idempotency at Enterprise minimum. `assume once` is only safe for pure-compute jobs (no side effects). `/gabe-plan` should BLOCK MVP + side-effect-job phase combinations.
- **Dead-letter = audit requirement.** For compliance/operational visibility, even MVP should have log + alert on terminal failure. Pure `drop` is only acceptable for throwaway prototype.
