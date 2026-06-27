# Milepost — milestone diary (auto-maintained)

While working on any task, keep a plain-markdown **milepost** so progress and context survive across sessions. Maintain it yourself, inline, as part of normal work — do not wait to be asked.

## Where it lives (per project)

`~/.claude/memory/milepost/<project-slug>/`
- `log.md` — append-only, timestamped milestone entries (newest at the bottom).
- `STATUS.md` — a short, living snapshot of where the task stands right now and what's next. Overwrite/update it; keep it current, not historical.

`<project-slug>` = the current working directory with `/` and spaces replaced by `-` and any leading `-` dropped. If unsure, use the working directory's base name. Create the folder and files on first milestone if they don't exist.

## When to write a milestone entry

Use judgment — record **meaningful** events only, not routine steps. Write an entry when:
- A deliverable, feature, or fix is **completed**.
- A notable **design / architectural decision** is made (record the *why*).
- A significant **blocker** is hit or resolved.
- The user **changes direction**, scope, or goals.
- The **current status materially changes**.

Do NOT log every edit, command, or intermediate step. Aim for high signal.

## How to write

1. Append to `log.md` in this format:

   ```markdown
   ## <YYYY-MM-DD HH:MM> — <one-line title>
   **Type:** deliverable | decision | blocker | direction | status
   **What:** <what happened, concretely>
   **Why:** <reasoning — required for decisions, else omit>
   **Next:** <immediate next step, or —>
   ```

2. Update `STATUS.md` so it reflects the new current state (a few lines: current goal, where things stand, next step, open questions).

3. Keep entries concise. Mention briefly that you logged it — do not narrate verbosely.

## Guardrails

- **Never log secrets, credentials, tokens, or sensitive file contents** — summarize instead.
- If a periodic `[milepost reminder]` arrives and no milestone actually occurred, do nothing and continue.
- The user can force an entry with `/milepost`, view/refresh status with `/status`, or synthesize patterns with `/reflect`.
