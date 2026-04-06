---
name: gabe-align
description: "Alignment guardian — shallow/standard/deep checks plus automatic checkpoint at commit/PR. Usage: /gabe-align [mode] [target] or /gabe-align init [project]"
---

# Gabe Align

Alignment guardian. Manual pre-flight checks + automatic checkpoint at commit/PR boundaries.

## Before Anything Else

Read the full skill definition from the gabe-align skill (`SKILL.md`) and the values from `VALUES.md`. Both are required. Also read `~/.kdbp/VALUES.md` (user-level) and `.kdbp/VALUES.md` (project-level) if they exist.

## Modes

### Mode 1: Standard (default)

**Usage:** `/gabe-align [target]`

Full alignment check against all loaded values (structural A1-A7 + user U* + project V*).

### Mode 2: Shallow (`shallow` | `sf` | `bf`)

**Usage:** `/gabe-align shallow [target]`

Core values + project values only. 3-5 line output. Quick sanity check.

### Mode 3: Deep (`deep` | `dp`)

**Usage:** `/gabe-align deep [target]`

Full check plus alignment brief with intent, risks, recommended approach, and open questions.

## Subcommands

### Init Project

**Usage:** `/gabe-align init [project-name]`

Create `.kdbp/` directory with BEHAVIOR.md and VALUES.md. Interactive — asks about project domain, maturity, and core values.

### Init User

**Usage:** `/gabe-align init-user`

Create `~/.kdbp/VALUES.md` with universal values for all projects. Interactive.

### Status

**Usage:** `/gabe-align status`

Show all loaded values (user + project) and whether `.kdbp/` exists.

### Migrate

**Usage:** `/gabe-align migrate`

Convert old `_kdbp/behaviors/` to new `.kdbp/` format.

### Evolve

**Usage:** `/gabe-align evolve`

Review value PASS/CONCERN frequency and suggest changes.

$ARGUMENTS
