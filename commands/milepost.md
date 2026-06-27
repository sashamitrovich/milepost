---
description: Force a milepost milestone entry for the current session now
---

# Record a milepost milestone now

Create a milestone entry for the current task, even if no automatic trigger fired.

Follow the Milepost policy (loaded from your global instructions). Specifically:

1. Determine `<project-slug>` from the current working directory (replace `/` and spaces with `-`, drop any leading `-`). Target directory: `~/.claude/memory/milepost/<project-slug>/`. Create it if missing.
2. Reflecting on the current session, append a concise entry to `log.md`:

   ```markdown
   ## <YYYY-MM-DD HH:MM> — <one-line title>
   **Type:** deliverable | decision | blocker | direction | status
   **What:** <what happened, concretely>
   **Why:** <reasoning — for decisions>
   **Next:** <immediate next step, or —>
   ```

3. Update `STATUS.md` to reflect the current state and next step.
4. Confirm the file paths written and give a one-line summary.

If the user supplied text after the command, use it as the focus/title of the entry. Never log secrets or sensitive contents.
