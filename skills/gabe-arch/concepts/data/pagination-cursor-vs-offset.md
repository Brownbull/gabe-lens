---
id: pagination-cursor-vs-offset
name: "Pagination: Cursor vs Offset"
tier: foundational
specialization: [data, web]
tags: [pagination, cursor, offset, scale]
prerequisites: []
related: [schema-evolution-expand-contract]
one_liner: "Offset pagination breaks at scale — cursors are the grown-up answer."
---

## Analogy

Reading a book: offset = "skip to page 500" (the typesetter still has to count 500 pages every time you ask). Cursor = "continue from this bookmark" (the bookmark remembers where you were). One scales with book size; the other doesn't.

## When it applies

- Any list endpoint returning more than a few dozen items
- Infinite-scroll UIs, search results, activity feeds
- API endpoints clients will hit repeatedly as new data arrives
- Any dataset expected to grow past a few thousand rows

## When it doesn't

- Truly bounded lists (e.g., "top 10 items of all time")
- Internal admin UIs where operational-scale offset is fine
- Small datasets where neither approach matters measurably

## Primary force

`OFFSET 100000 LIMIT 50` forces the database to scan and discard the first 100,000 rows on every call — expensive and gets worse as pagination goes deeper. Cursor pagination uses "WHERE id > last_seen_id LIMIT 50" which uses the index directly and runs in constant time regardless of depth. The tradeoff: cursors don't support "jump to page 500," only "next page from where I left off." For most user-facing lists, that's what you actually wanted.

## Common mistakes

- Offset pagination with deep results (timeout, slow queries, DB CPU spike)
- Cursors based on non-unique fields (ties produce duplicates or skips)
- Exposing raw DB primary keys as cursors (couples API to schema; obfuscate)
- No tie-breaker in ORDER BY (same-timestamp rows arrive inconsistently)
- No max page size (one caller requesting limit=100000 takes down your DB)

## Evidence a topic touches this

- Keywords: pagination, cursor, offset, LIMIT, page_token, next_cursor
- Files: `**/api/*.py`, `**/endpoints/*`, `**/repositories/*`
- Commit verbs: "add pagination", "switch to cursor", "replace offset", "next_cursor"

## Deeper reading

- GitHub GraphQL API: Relay-style cursor pagination
- Stripe API pagination docs
- "Use The Index, Luke" — pagination anti-patterns
