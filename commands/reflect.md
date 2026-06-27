---
description: Synthesize patterns and a progress summary from milepost entries
---

# Reflect on the milepost

1. Determine `<project-slug>` from the current working directory (or, if the user names a project, use that). Milepost dir: `~/.claude/memory/milepost/<project-slug>/`.
2. Read `log.md` (all milestone entries) and `STATUS.md`.
3. Produce a synthesis covering:
   - **Progress so far** — what's been accomplished, in order.
   - **Key decisions & their rationale** — pulled from `decision`-type entries.
   - **Recurring blockers or themes** — patterns worth noting.
   - **Where things stand & what's next** — reconcile with `STATUS.md`.
4. Write the synthesis to `~/.claude/memory/milepost/<project-slug>/reflections/<YYYY-MM-DD>.md` and show a short summary.

If no entries exist, say so. Never include secrets or sensitive contents in the reflection.
