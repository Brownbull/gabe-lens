# Section: Deployment/Release

**Trigger tags:** `migration`, `rollout`

**Purpose:** Deployment and release-safety posture. Applies to phases that ship code to production environments, especially those involving schema migrations, feature flags, or multi-stage rollouts.

## Dimensions (4)

| Dimension            | MVP                  | Δ(M→E) | Enterprise           | Δ(E→S) | Scale               |
|----------------------|----------------------|--------|----------------------|--------|---------------------|
| Feature flags        | hardcoded            | L      | env flag             | M      | + targeted rollout  |
| Canary               | all-or-none          | L      | % traffic            | M      | + auto rollback     |
| Rollback plan        | git revert           | L      | prev-image revert    | M      | + DB fwd-compat     |
| Migration order      | deploy-then-migrate  | XL     | migrate-first gated  | M      | + expand/contract   |

## Notes

- **Feature flags:** MVP = `if FEATURE_X:` hardcoded. Enterprise = env-var driven flag. Scale = targeted rollout (user segments, % ramps via LaunchDarkly/GrowthBook/Unleash).
- **Canary:** MVP = deploy to all prod at once. Enterprise = gradual % traffic split. Scale = + auto rollback on metric regression.
- **Rollback plan:** MVP = `git revert` + redeploy. Enterprise = pinned previous image/release artifact, fast revert. Scale = + forward-compatible DB migrations (old code can read new schema during rollback window).
- **Migration order:** XL skip MVP→Ent. MVP "deploy-then-migrate" = old code runs against new schema briefly = runtime errors. Enterprise = migrate-first + deploy-gated (new code waits on migration ready signal). Scale = expand/contract pattern (additive migrations, no breaking changes in a single release).

## Tier-cap enforcement

- **MVP phase:** feature flag SDK integration (LaunchDarkly, GrowthBook), canary routing rules, expand/contract migration scaffold trigger escalation.
- **Enterprise phase:** auto-rollback automation (Argo Rollouts, Flagger), forward-compat migration linter trigger Scale escalation.

## Known drift signals

| Pattern                                     | Tier floor | Finding severity  |
|---------------------------------------------|------------|-------------------|
| `launchdarkly-server-sdk` / `GrowthBook` SDK import | Enterprise | TIER_DRIFT-MED |
| Canary routing config (Argo Rollouts, Flagger, Istio VirtualService w/ weights) | Enterprise | TIER_DRIFT-MED |
| Auto-rollback rules tied to SLO metrics    | Scale      | TIER_DRIFT-HIGH   |
| Expand/contract migration pattern (add col nullable → backfill → NOT NULL + drop old col) | Scale | TIER_DRIFT-MED |
| Forward-compat schema guard (`strawberry` subschema check, custom CI lint) | Scale | TIER_DRIFT-MED |

## Red-line items

- **Migration order on shared-DB apps.** Any phase with schema change + code deploy in same release MUST be Enterprise+ on Migration order. MVP `deploy-then-migrate` = minutes of runtime errors during deploy = user-visible outage. Even prototype-tagged phases on real-DB should escalate.
- **Rollback plan = mandatory for production.** No non-prototype phase should be MVP on Rollback plan. Even if simple, must have "how do we revert" documented.
