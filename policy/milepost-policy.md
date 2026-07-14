# Milepost — milestone diary (auto-maintained)

While working on any task, keep a plain-markdown **milepost** so progress and context survive across sessions. Maintain it yourself, inline, as part of normal work — do not wait to be asked.

## Where it lives (per project)

`~/.claude/memory/milepost/<project-slug>/`
- `log.md` — append-only, timestamped milestone entries (newest at the bottom).
- `STATUS.md` — a short, living snapshot of where the task stands right now and what's next. Overwrite/update it; keep it current, not historical.

`<project-slug>` = the canonical slug of the project root: take the git repository root of the current working directory (the cwd itself if not inside a git repo), lowercase it, replace every run of non-alphanumeric characters with a single `-`, and trim leading/trailing `-`. Example: `/Users/me/dev/My_App/subdir` → `users-me-dev-my-app` (when `My_App` is the repo root). When available, compute it with `bash ~/.claude/hooks/milepost-slug.sh` instead of deriving it by hand — the hooks use the same helper, so everything agrees on the diary location. Create the folder and files on first milestone if they don't exist.

**Opt-out:** if a `.no-milepost` file exists at the project root, do not journal that project at all — no diary, no entries, no status.

## When to write a milestone entry

Use judgment — record **meaningful** events only, not routine steps. Write an entry when:
- A deliverable, feature, or fix is **completed**.
- A notable **design / architectural decision** is made (record the *why*).
- A significant **blocker** is hit or resolved.
- The user **changes direction**, scope, or goals.
- The **current status materially changes**.

Do NOT log every edit, command, or intermediate step. Aim for high signal.

**Decide autonomously.** Applying these criteria is your job, not the user's. Never ask the user whether something is worth logging or for permission to log — if it meets the bar above, just log it as part of finishing the work; if it doesn't, stay silent. Logging is a normal side effect of doing the task, not a separate request that needs sign-off.

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

- **Never write secret values into the diary**: passwords, API keys, tokens, private keys, session cookies, connection strings or URLs containing credentials, or the contents of credential files. Refer to secrets by *location or name only* (e.g. "token stored in `.ha_token`", "password in project `.creds`"), never by value.
- **Minimize near-secrets too.** Only include internal IPs/hostnames, device serial numbers, account identifiers, or third-party personal data when they are genuinely needed to resume the work — prefer a role description ("the HA box", "the battery hub") when it carries the same information.
- A PreToolUse guard hook mechanically blocks diary writes containing secret-shaped content. If a diary write is denied by it, **rewrite the entry to summarize — never try to work around the guard** (encoding, splitting, or writing elsewhere).
- Diaries are plaintext under `~/.claude/memory/milepost/`. Never commit, sync, or share them, and never copy diary contents into project files or external services.
- If a periodic `[milepost reminder]` arrives and no milestone actually occurred, do nothing and continue.
- The user can force an entry with `/milepost`, view/refresh status with `/status`, or synthesize patterns with `/reflect`.
