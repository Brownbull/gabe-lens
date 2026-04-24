# P9 — cross-product-infra-coupling

## Evidence source

BoletApp `CLAUDE.md` INC-001: BoletApp and Gustify share the same Firebase project (`boletapp-d609f` prod, `boletapp-staging` staging). Firestore rules are **per-project** — deploying `firebase deploy --only firestore:rules` from BoletApp would overwrite Gustify's rules. Cloud Functions are safe (separate codebases: `default` vs `gustify`) but a rule deploy from the wrong repo is a cross-product incident.

## Red-line questions

- Does any infrastructure config (Firebase project, Supabase project, Terraform workspace, GCP / AWS account) live in multiple repos?
- If yes, are there CI guardrails preventing cross-product deploy from the wrong repo?
- Is the coupling documented in every coupled project's CLAUDE.md / README with an INC-NN identifier?

## Detection — doc pass

- Grep for `INC-\d+` identifiers in `CLAUDE.md`, `README.md`, `.kdbp/DECISIONS.md`, `.kdbp/BEHAVIOR.md`.
- Grep for "shared" / "same" / "both" combined with Firebase / Supabase / Terraform / AWS / GCP / database names.
- `.kdbp/ENTITIES.md` or `.kdbp/STRUCTURE.md`: infrastructure topology diagram or list.

## Detection — code pass

- `find . -name "firebase.json" -o -name "firebaserc" -o -name ".firebaserc" -o -name "supabase/config.toml" -o -name "*.tfvars"` — enumerate infra config files.
- Check for identical `project_id` / `project` / `workspace` across sibling repos (cross-repo grep if possible).
- Env files: `grep -r "FIREBASE_PROJECT_ID\|SUPABASE_PROJECT_ID\|NEXT_PUBLIC_FIREBASE_PROJECT_ID" .env* 2>/dev/null` — compare with sibling product.
- Deploy scripts: `grep -rn "firebase deploy\|supabase db push\|terraform apply" package.json scripts/ deploy/` — any deploy commands that touch shared resources?

## Detection — commit pass

- `/shared.*project|same.*project/i` in subject combined with infra keywords
- `/overwrote|overwrote rules|overwrite/i`
- `/cross.?product|cross.?app/i`
- `/incident|INC-/i`

## Tier impact

- MVP: surfaces if any shared infra exists (even if zero-risk today).
- Enterprise: plus: CI guardrail required.
- Scale: plus: separate accounts per product mandated.

## Severity default

CRITICAL (because the blast radius is another product's outage).

## ADR stub template

**Decision:** Shared infrastructure between products is documented as INC-NN in every coupled repo's CLAUDE.md with: the shared resource, the specific command that would break the sibling, and the guardrail (CI check, deploy script restriction, or operational "DO NOT run from here" note).
**Rationale:** BoletApp INC-001. Silent infra sharing fails catastrophically — a routine `firebase deploy` from one repo can outage the sibling. Documentation + CI guard is the minimum; separate projects is the long-term fix.
**Alternatives considered:**
1. Separate projects per product — preferred long-term, cost / migration may defer.
2. Docs-only reminder — rejected; depends on every future contributor reading CLAUDE.md before deploy.

## Open Question template

**Question:** Which infrastructure resources (Firebase / Supabase / Terraform / DB / queues) are shared between this product and sibling products? What prevents a deploy from overwriting the sibling?

## Rule template

**Rule:** Any shared infrastructure is declared as INC-NN in CLAUDE.md with a specific "DO NOT deploy X from here" note AND a CI guard on the deploy script (check repo identity + target project before executing). Unshared equivalents are the long-term fix.
**Detection:** grep `INC-\d+` in CLAUDE.md; CI deploy script has preflight check for repo-to-project match.
