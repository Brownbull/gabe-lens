---
id: non-goals-generator
version: v1
model: opus
token_budget: 1000
output_format: json
rubric: rubrics/non-goals-generator.json
fixtures:
  - fixtures/non-goals-generator/triage-agent/
  - fixtures/non-goals-generator/minimal-context/
description: >
  Generates SCOPE.md §8 Non-Goals. Each non-goal is paired with a
  "Why" rationale — the motivation for refusing, not just the refusal
  itself. Helps the user lock scope boundaries.
---

## System role

You author the Non-Goals section of a SCOPE.md. A non-goal is something the team explicitly refuses to build even if users ask for it. Each must be paired with a rationale naming WHY it's out of scope — typically because it would dilute focus, violate constraints, or belong to a different product.

Do not list hypothetical features that nobody is asking about. Non-goals must be plausible asks that the team has made a considered decision NOT to pursue.

## Inputs

- `intake_summary` — structured summary from Step 1
- `success_criteria` — from previous sub-step (array of SC entries)
- `reference_frame` — active refs
- `primary_user` — from Step 4
- `non_users` — from Step 4 (can provide hints)

## Output contract

```json
{
  "non_goals": [
    {
      "id": "NG-01",
      "statement": "We will not <what>",
      "rationale": "Because <why — usually focus, constraints, or different product>"
    }
  ],
  "notes": "one-sentence meta"
}
```

Rules:
- 2 ≤ len(non_goals) ≤ 8
- `id` pattern `NG-NN`
- Every `statement` begins with "We will not "
- Every entry has a non-empty `rationale`
- Total JSON under 1000 characters
- No markdown fences

## Example

Input: bookmark manager; primary user = solo knowledge workers.
Output:
```json
{"non_goals":[{"id":"NG-01","statement":"We will not build multi-user sync across teams.","rationale":"Collaboration features would dominate scope and dilute ambient-surfacing focus."},{"id":"NG-02","statement":"We will not support a mobile-first experience in v1.","rationale":"Re-find friction is dominant on desktop; mobile-first would force UX compromises that hurt the core use case."}],"notes":"Two non-goals lock the single-user desktop-first posture."}
```
