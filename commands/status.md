---
description: Show or refresh the current task status from the milepost
---

# Milepost status

1. Determine `<project-slug>` with `bash ~/.claude/hooks/milepost-slug.sh` and locate `~/.claude/memory/milepost/<project-slug>/STATUS.md`.
2. If it exists, read and display its current contents.
3. Then, reflecting on the current session, update `STATUS.md` so it accurately captures: the current goal, where things stand right now, the immediate next step, and any open questions. Keep it short and present-tense (a living snapshot, not a history — that's what `log.md` is for).
4. If no milepost exists yet for this project, say so and offer to start one with `/milepost`.

If the user supplied text after the command, treat it as an update to fold into the status.
