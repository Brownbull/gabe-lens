---
name: gabe-teach
description: "Consolidate the human's architect-level understanding of recent changes. Detects WHY/WHEN/WHERE topics from commits, explains with analogies, verifies with Socratic questions, tracks in .kdbp/KNOWLEDGE.md. Usage: /gabe-teach [topics|status|free]"
---

# Gabe Teach

Countermeasure for "the human can't keep up with AI-paced changes." Keeps the human at architect-level understanding: WHY decisions were made, WHEN patterns apply, WHERE files belong. Not code syntax — reasons.

## Procedure

### Step 0: Detect mode

Parse `$ARGUMENTS`:
- `topics` (default when `.kdbp/` exists) — session-aware, KDBP mode
- `status` — show KNOWLEDGE.md summary, no teaching
- `free [concept]` — raw analogy generation for an arbitrary concept (invokes `gabe-lens` skill directly)

If `.kdbp/` doesn't exist: fall back to `free` mode with a note: "No KDBP detected. Running in free mode. Run `/gabe-init` to enable knowledge tracking."

### Step 1: Status mode

If `status`:
1. Read `.kdbp/KNOWLEDGE.md`
2. Show summary:
   ```
   KNOWLEDGE MAP — [project name]

   Total topics: N
     verified:      [N] (avg score: X.X/2)
     pending:       [N]
     skipped:       [N]
     already-known: [N]
     stale:         [N]  ← verified >90 days ago

   Recent sessions: [last 3 /gabe-teach dates]

   Classes:
     WHY:   [N] topics
     WHEN:  [N] topics
     WHERE: [N] topics
   ```
3. If stale count > 0, suggest: "Run `/gabe-teach topics` to refresh stale topics."
4. Stop.

### Step 2: Topics mode — extract candidate topics

Read, then extract topics deterministically. No LLM for diff analysis — use concrete signals:

**From LEDGER.md:**
1. Find commits since the last `## YYYY-MM-DD — /gabe-teach` entry (or all commits if first run)
2. For each commit, parse:
   - Commit message prefix (`feat:`, `refactor:`, `fix:`, etc.)
   - Changed files (read from the LEDGER entry)

**From git (if LEDGER lookup fails):**
- `git log --oneline --since="7 days ago"`
- `git log --name-only --since="7 days ago"`

**Topic extraction rules (deterministic):**

| Signal | Topic class | Topic template |
|--------|-------------|----------------|
| Commit prefix `feat:` or `refactor:` | WHY | "Why we chose [approach] for [commit subject]" |
| Pattern across 2+ commits (same folder, same type of change) | WHEN | "When to apply [detected pattern]" |
| New file added in a commit | WHERE | "Why `[new file]` lives in `[folder]` (static gravity well)" |
| Modified `.kdbp/DECISIONS.md` | WHY | Read the decision — it is its own topic |
| Modified `.kdbp/PLAN.md` phase transition | WHY | "Why we moved to Phase N" |

**Deduplication:**
1. For each candidate topic, normalize to short form (2-5 words)
2. Cross-reference with existing KNOWLEDGE.md rows
3. Skip if matches an existing `verified` (not stale) or `already-known` topic
4. Keep if matches `pending`, `skipped`, or `stale` — re-surface

**Naming candidate topics:**
Use a single short LLM call (one roundtrip) to turn raw commit-message snippets into concept-level topic names. Input: list of raw signals. Output: clean topic names grouped by class. No code analysis, no diff reading — names only. This is the only LLM cost in topic extraction.

### Step 3: Present menu

Cap at **5 topics shown, 3 selectable** per session (prevents quiz fatigue).

```
TEACH: Topics from recent changes

Commits covered: [N] since [date]

Pending topics:
  [1] WHY   — Why we chose absorption over accumulation for km-ingest
  [2] WHEN  — When to use /gabe-plan vs /plan
  [3] WHERE — Why knowledge-awareness.json lives in hooks/ not commands/
  [4] WHY   — Why the filing loop writes to categories/ not raw/
  [5] WHERE — Why PLAN.md sits at .kdbp/ root, not .kdbp/plans/

Pick up to 3 (e.g., "1,3,5" or "all" or "skip"):
```

If user picks `skip`: log to KNOWLEDGE.md as "session: skipped all", stop.

### Step 4: Teach each selected topic

For each topic, execute this cycle:

**4a. Explain** — invoke the `gabe-lens` skill to translate the concept into an analogy. Reference the source commit. Keep it under 200 words.

**4b. Ask** — 2 Socratic questions from these templates (pick the 2 most relevant):

| Template | What it tests |
|----------|--------------|
| "Why did we choose X instead of Y here?" | Understands the *decision*, not the code |
| "When would you NOT apply this pattern?" | Knows the boundary conditions |
| "What would break if we removed X?" | Understands the load-bearing role |
| "If you saw a similar problem tomorrow, what's the first thing you'd check?" | Can transfer the pattern |
| "What did we sacrifice by choosing this approach?" | Understands trade-offs |
| For WHERE topics: "If you created a new `[similar file type]` tomorrow, where would it go and why?" | Understands the structural attractor |

**4c. Evaluate response:**

| Human response | Classification |
|----------------|---------------|
| Reasoning covers the WHY/WHEN/WHERE correctly | `verified`, score 2/2 |
| Reasoning partial — gets the gist but misses a key constraint | `verified`, score 1/2, show the missing piece |
| Reasoning off — wrong mental model | mark `pending`, explain correctly, re-surface next session |
| "skip" / "pass" | mark `skipped` |
| "I already know this" (before the questions) | Ask ONE sanity question; if correct → `already-known`; if wrong → `pending` |

**4d. Feedback:**
- If verified 2/2: short confirmation + one-line "here's the durable takeaway"
- If verified 1/2: show the missing piece, confirm the rest
- If pending: explain the correct reasoning, note that this will re-surface

### Step 5: Update KNOWLEDGE.md

For each topic discussed, update or insert a row in the Topics table:

```
| T[N] | WHY|WHEN|WHERE | [topic name] | verified|pending|skipped|already-known | [today] | [today if verified] | [score] | [commit] |
```

Append a session entry:

```
### [YYYY-MM-DD] — /gabe-teach ([post-commit|post-push|manual])
- Commits covered: [list]
- Presented: T1, T2, T3
- Verified: T1 (2/2), T3 (1/2)
- Skipped: T2
- Already-known: —
```

### Step 6: Log to LEDGER.md

```
## [YYYY-MM-DD HH:MM] — /gabe-teach
TOPICS: presented N, verified M, skipped K, already-known J
PENDING: [count after this session]
```

### Step 7: Exit message

```
TEACH SESSION COMPLETE
  Verified: [N] topic(s)
  Remaining pending: [M]

Next: run /gabe-teach again after your next /gabe-commit or /gabe-push to stay current.
```

---

## Staleness handling

When running `/gabe-teach topics`:
- Before presenting new topics, check for topics with `verified` status and `Verified Date` >90 days ago
- Mark them `stale`
- Include in the menu with prefix `[stale]` — high priority to re-verify
- If >3 stale topics, show warning at top of menu: "⚠ You have N topics verified >90 days ago. Knowledge can drift — consider re-verifying."

## Already-known sanity check

When the human claims `already-known`, DO NOT mark as already-known immediately. Ask ONE question first:
- "Quick sanity check: [one targeted question]"
- If correct → `already-known` with note "sanity-checked"
- If wrong → `pending`, explain correctly, note "claimed known but missed X"

This is the countermeasure to human self-deception under AI-paced pressure.

## Interaction with other gabe commands

- Called after `/gabe-commit` if N new topics detected (suggestion, not blocking)
- Called after `/gabe-push` if pending topics >= 2 (suggestion, not blocking)
- `/gabe-teach status` is zero-cost — run anytime
- Does NOT run during `/gabe-plan` — planning is forward-looking, teaching is retrospective

$ARGUMENTS
