---
name: <project name>
version: 1
status: active
created: <YYYY-MM-DD>
last_rule_event: <YYYY-MM-DD>
---

# RULES — <project name>

> **Scar-tissue constraints.** This file holds PR-checklist-shaped rules derived from specific past failures (in this project or adjacent ones). Every rule cites its source incident. The file is the load-bearing companion to `.kdbp/DECISIONS.md` — DECISIONS records *what we chose*; RULES records *what we've paid to learn*.

**Meta-rule:** a rule without evidence is speculation. Every R-entry cites a commit, file, retro, or incident. If the citation becomes irrelevant (pattern retired, system reshaped), mark the rule `retired` with a date — don't carry dead dogma forward.

**Maintained by:** `/gabe-debt` (see `skills/gabe-debt/SKILL.md`). `/gabe-debt extract-rules` mines retros + LESSONS files to propose new R-entries. `/gabe-review` consumes this file as a severity-escalation input (code that violates R-NN auto-escalates to CRITICAL with citation).

---

## 1. Rules {#rules}

<!-- Each rule is one H3 block. IDs R1, R2, … are stable; never renumber. Retired rules stay in place with status: retired. -->

### R1 — <short rule handle> {#r1}
**Evidence:** <retro-file §X | commit SHA | file:line | incident-ID>
**Rule:** <one or two sentences — PR-checklist shape. "Every X must Y because Z.">
**Detection:** <how to check automatically — grep signature, lint rule, CI check, code-review perspective>
**Applies to:** <phases (B0, I2, …) | REQs (REQ-01) | paths (src/features/scan/*)>
**Status:** active
**Sources:** <gabe-debt extract-rules YYYY-MM-DD | manual | LESSONS.md §N>

<!--
Template for additional rules (copy-paste, increment ID):

### R2 — <short rule handle> {#r2}
**Evidence:** …
**Rule:** …
**Detection:** …
**Applies to:** …
**Status:** active
**Sources:** …

-->

---

## 2. Phase cross-reference {#phase-xref}

<!-- Populated once rules accumulate. Built automatically by /gabe-debt audit-rules. -->

| Rule | Phases / REQs | Acceptance criterion the rule adds |
|---|---|---|
| R1 | <PLAN.md phase IDs> | <what CI / review must verify> |

---

## 3. Retired rules {#retired}

<!-- Rules whose evidence is no longer load-bearing. Keep for history; do not renumber. -->

<!-- Example:
### R<n> — <handle> — RETIRED <YYYY-MM-DD>
**Retirement rationale:** <why no longer relevant — system reshape, deprecation, pattern subsumed>
**Original rule:** <quote>
-->

---

## 4. Change Log {#change-log}

Append-only. Each entry: date, action, summary.

| Date | Action | Summary |
|---|---|---|
| <YYYY-MM-DD> | init | RULES.md scaffolded via `/gabe-init`. |
