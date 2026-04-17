---
id: _schema-example
name: Schema Example (reference file, not a real concept)
tier: foundational
specialization: [agent]
tags: [reference, schema, example]
prerequisites: []
related: []
one_liner: "Reference concept file showing the full frontmatter + body template."
---

# Purpose of this file

Not a real concept. This is the canonical example every new concept file should mirror structurally. Delete nothing, rename nothing, reorder nothing — the commands in `/gabe-teach arch` parse sections by heading.

## Analogy

A blueprint for a house: every room is drawn to scale, every door swings the right way, every window faces the sun. New builders copy the blueprint and change only the details; the shape stays the same.

## When it applies

- Creating a new concept file in any specialization.
- Reviewing a pull request that adds concepts to the catalog.
- Onboarding a contributor who hasn't written concept files before.

## When it doesn't

- Editing an existing concept's Analogy or Primary force — leave the template structure alone, just change the prose.
- Rendering in `/gabe-teach arch show` — that flow reads body sections by heading name, not by example.

## Primary force

A consistent template lets the commands parse concept files without per-file logic. If every concept uses the same six sections with the same headings in the same order, tagging, rendering, and progression logic become one code path instead of seven.

## Common mistakes

- Renaming `## Primary force` to `## Why` — the command looks for the literal heading.
- Omitting `## Evidence a topic touches this` — without it, deterministic tagging can't find this concept, only the LLM fallback can.
- Listing more than one force — if you have two, write two concepts.
- Writing the `one_liner` as a full sentence — keep it under 15 words, no period required.

## Evidence a topic touches this

- Keywords: schema-example, reference file (this concept intentionally unmatchable in real projects)
- Files: n/a
- Commit verbs: n/a

## Deeper reading

- `skills/gabe-arch/SKILL.md` — full schema definition and rules
- `skills/gabe-arch/TAXONOMY.md` — tiers × specializations map
