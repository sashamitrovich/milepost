<div align="center">

# 📔 milepost — Long-Term Memory for Claude Code

### A milestone-triggered, in-session work diary that gives Claude Code persistent, plain-markdown memory across sessions — no database, no lock-in, fully greppable.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](./LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-plugin-8A2BE2.svg)](https://code.claude.com)
[![Storage](https://img.shields.io/badge/storage-plain%20markdown-blue.svg)](#what-it-writes)
[![No Database](https://img.shields.io/badge/database-none-lightgrey.svg)](#how-milepost-compares)

**Keywords:** Claude Code memory · persistent memory for Claude Code · long-term memory plugin · AI agent diary · session memory · markdown work log · Claude Code plugin · agent context persistence · milestone logging

</div>

---

## TL;DR

**milepost** is a free, open-source [Claude Code](https://code.claude.com) plugin that turns Claude into an agent with a memory. As you work, Claude automatically writes a **diary of meaningful milestones** — completed deliverables, key decisions (and *why* they were made), blockers, and changes in direction — plus a living **STATUS.md** of where things stand. Everything is stored as **plain markdown files you own**, so you can `grep` it, `git` it, export it, or read it in any editor. No SQLite, no vector DB, no cloud, no lock-in.

> Pick up a long-running task days or weeks later and Claude already knows what you did, what you decided, and what's next.

```
/plugin marketplace add sashamitrovich/milepost
/plugin install milepost@milepost
```

---

## Why milepost exists

Claude Code is brilliant within a session — and forgetful between them. Close the terminal and the reasoning, the decisions, the dead-ends you already ruled out are gone. For a quick edit that's fine. For a **project you return to over weeks**, it means re-explaining context every single time.

Existing memory tools each force a trade-off:

- **Database-backed memory** (e.g. claude-mem) captures everything automatically — but your memory lives in SQLite + a vector store. Hard to read, harder to export, easy to get locked into.
- **Session-end / manual diaries** (e.g. claude-diary) write plain markdown — but only when *you* run a command, or after a session is already over.

milepost takes the third path: **plain markdown, written *as you go*, triggered by milestones — not by a clock, a command, or a database.**

---

## How it works

Deciding *"a real milestone just happened"* is a judgment call — and only the model can make it. So milepost isn't a dumb cron job; it's two cooperating parts:

| Part | What it is | What it does |
|------|------------|--------------|
| 🧠 **Policy** | A global instruction added to `~/.claude/CLAUDE.md` | Tells Claude *when* a milestone is worth recording and *how* to write it — using its normal file tools, inline, while working. |
| ⏱️ **Nudge** | A throttled `Stop` hook (default: once / 15 min) | Quietly reminds Claude to check for unrecorded milestones on long sessions, so logging stays consistent without nagging every turn. |
| 📖 **Recall** | A read-only `SessionStart` hook | At the start of every session, surfaces **the current project's** `STATUS.md` back into context (matched via a canonical, git-root-aware project slug), plus a one-line index of your other tracked projects — so prior work and next steps are visible without asking, and the injected context stays small no matter how many projects you track. Never writes to the diary. |
| 🛡️ **Secret guard** | A `PreToolUse` hook on `Write`/`Edit`/`Bash` | Mechanically **blocks** any diary write containing secret-shaped content (API keys, tokens, private keys, JWTs, credential assignments, URLs with embedded passwords) and tells Claude to rewrite the entry referencing secrets by location, never by value. The policy alone asks nicely; this enforces it. |

The result: **automatic, milestone-aware journaling** that doesn't interrupt your flow and doesn't depend on you remembering to run anything.

---

## What it writes

Per project, in a folder you fully control:

```
~/.claude/memory/milepost/<project>/
├── log.md        # append-only, timestamped milestone entries
├── STATUS.md     # living snapshot: current goal, where things stand, what's next
└── reflections/  # optional /reflect syntheses
```

A real entry looks like this:

```markdown
## 2026-06-27 14:32 — Converted architect PDF to per-page JPEGs
**Type:** deliverable
**What:** Rendered all 4 A3 pages at 200 DPI with ImageMagick.
**Why:** Client needed individual page images for review.
**Next:** —
```

Readable by humans. Parseable by machines. Owned by you.

---

## Features

- 🪶 **Plain markdown, zero database** — greppable, git-friendly, exportable, future-proof.
- 🎯 **Milestone-triggered, not time-triggered** — high-signal entries, not noisy logs.
- 🔁 **In-session & automatic** — written *while* Claude works, not after you've closed the terminal.
- 🌍 **Works across every project** — one global install; per-project diaries.
- 🧭 **Living status file** — always know the current state and next step of any task.
- 🛠️ **Manual controls** — `/milepost`, `/status`, `/reflect` when you want them.
- 🔒 **Privacy-first, enforced** — policy tells Claude to summarize secrets, and a `PreToolUse` guard hook mechanically blocks secret-shaped content from ever landing in the diary. Per-project opt-out via a `.no-milepost` file.
- ↩️ **Reversible & safe** — idempotent installer with automatic backups; clean uninstaller that keeps your data.

---

## Quick start

**Option A — plugin install (recommended).** Inside Claude Code:

```
/plugin marketplace add sashamitrovich/milepost
/plugin install milepost@milepost
```

Everything is wired natively: the commands, the nudge, the recall, and the secret guard load from the plugin, and the policy is injected at session start (your `CLAUDE.md` is never touched). First time Claude journals, approve the diary write with "always allow" — the plugin cannot pre-grant permissions for you. Remove with `/plugin uninstall milepost@milepost`; your diaries stay put.

**Option B — script install.** For older Claude Code versions, or if you prefer the policy as a visible block in your own `CLAUDE.md` and pre-granted diary-write permissions:

```bash
git clone https://github.com/sashamitrovich/milepost.git
cd milepost && bash install.sh   # idempotent; backs up & merges, never overwrites
```

Remove with `bash uninstall.sh` — diaries stay put.

> Use **one** install mode, not both — running both duplicates the hooks (harmless but noisy). The diary location and format are identical either way, so you can switch modes without losing anything.

---

## Commands

| Command | What it does |
|---------|--------------|
| `/milepost [focus]` | Force a milestone entry right now. |
| `/status [update]` | Show — and refresh — the current status of this project's task. |
| `/reflect` | Synthesize progress, key decisions, and recurring themes from the log. |

---

## Configuration

| Setting | Default | Description |
|---------|---------|-------------|
| `MILEPOST_NUDGE_INTERVAL` | `900` (15 min) | Minimum seconds between nudges, per project. Raise it to journal less often; lower it to journal more. |
| `.no-milepost` file | — | Drop an empty `.no-milepost` file at a project's root to exclude that project entirely: no diary, no nudges, no recall. For client work or anything you'd rather keep out of the diary. |
| `MILEPOST_STRICT` | `0` | Set to `1` to make the secret guard also block **near-secrets**: IP addresses and e-mail addresses. Opt-in, because many legitimate diaries reference internal hosts. Set it where Claude Code's hooks see it — e.g. in `settings.json` under `"env": {"MILEPOST_STRICT": "1"}` or in your shell profile. |

Prefer zero hooks? Skip the nudge entirely — the `CLAUDE.md` policy works on its own; it just leans on the model to remember during very long sessions.

---

## How milepost compares

| | **milepost** | claude-mem | claude-diary |
|---|:---:|:---:|:---:|
| Storage | **Plain markdown** | SQLite + vector DB | Plain markdown |
| Greppable / exportable | ✅ | ⚠️ via export | ✅ |
| Writes *during* a session | ✅ | ✅ | ❌ |
| Milestone-aware (high-signal) | ✅ | ⚠️ captures everything | ⚠️ session-level |
| Trigger | **Milestones** | Continuous | Manual / pre-compact |
| Living status file | ✅ | ❌ | ❌ |
| Database required | **No** | Yes | No |

> Honest caveat: milestone detection is a *judgment*, so it's best-effort — it may occasionally over- or under-log, and entries use a little of your working session's tokens. `/milepost` is the manual backstop.

---

## FAQ

### What is the best way to give Claude Code long-term memory?
Use a plugin that persists context to durable, portable storage. **milepost** does this with plain-markdown files written as you work, so your memory is readable, greppable, and never locked inside a database.

### Does Claude Code remember things between sessions?
Not on its own. Claude Code is stateless across sessions beyond `CLAUDE.md`. milepost adds true cross-session memory by journaling milestones and a live status file that Claude reads back later.

### How is milepost different from claude-mem?
claude-mem captures everything into a SQLite + vector database. milepost stores **high-signal milestones as plain markdown** — easier to read, version, export, and trust, with nothing to lock into.

### Does milepost use a database or send my data anywhere?
No. Everything stays in local markdown files under `~/.claude/memory/milepost/`. No database, no cloud, no telemetry.

### Will it log secrets or sensitive code?
Defense in depth, not just a polite instruction:
1. **Policy** — Claude is told to reference secrets by location only ("token stored in `.ha_token`"), never by value, and to minimize near-secrets (internal IPs, serials, third-party personal data).
2. **Guard hook** — a `PreToolUse` hook scans every write targeting the diary directory (including shell redirection via `Bash`) and *denies* anything matching secret patterns: private-key blocks, AWS/GitHub/Slack/Google/`sk-`-style keys, JWTs, bearer tokens, `password=`/`api_key:`-style assignments, URLs with embedded credentials, plus a **high-entropy catch-all** for unknown token formats (≥32-char base64url-ish runs mixing upper/lower/digits — tuned so git SHAs, UUIDs, paths, and identifiers don't trip it).
3. **Strict mode** — `MILEPOST_STRICT=1` additionally blocks IP addresses and e-mail addresses, for client work and privacy-sensitive setups.
4. **Audit** — you can scan existing diaries anytime: `bash ~/.claude/hooks/milepost-secret-scan.sh < ~/.claude/memory/milepost/<project>/log.md` (exit 1 + pattern names on a hit).
5. **Opt-out** — a `.no-milepost` file at a project's root keeps that project out of the diary entirely.

### How is the diary protected on disk?
Diaries are plaintext markdown, owned by you. The installer restricts `~/.claude/memory/milepost/` to owner-only access (`chmod 700`). There is deliberately **no at-rest encryption**: milepost's whole design is that Claude reads and writes the diary with its ordinary file tools, and encrypting it would break that (and your greppability) while adding key management — use full-disk encryption (FileVault/LUKS/BitLocker), which covers the stolen-device case properly. Treat the diary dir like your shell history: local, private, never committed or synced to shared storage.

### Can a malicious repo trick Claude into leaking my diary?
The theoretical risk with any memory system: instructions hidden in a repo's files could ask the agent to copy remembered content somewhere it doesn't belong (prompt injection). milepost's policy explicitly forbids copying diary contents into project files or external services, and the diary only ever contains milestone summaries — not credentials (see the guard above). For projects where even summaries are sensitive, use `.no-milepost` so there is nothing to leak. Review what agents write, as always.

### Do I have to approve every diary write?
No. The installer adds two narrowly-scoped permission allow-rules to `settings.json` — `Edit(~/.claude/memory/milepost/**)` and `Write(~/.claude/memory/milepost/**)` — so Claude can journal without prompting you each time. The grant is limited to the milepost memory directory and nothing else; `uninstall.sh` removes it.

### Is it safe to install? Can I remove it cleanly?
Yes. The installer is idempotent, backs up `settings.json` and `CLAUDE.md` before editing, and merges rather than overwrites. `uninstall.sh` removes the wiring (hooks, policy block, and the scoped write permissions) and leaves your diaries intact.

### Does it work for any programming language or project?
Yes — milepost is language- and framework-agnostic. It journals your work, not your code, so it works for software, writing, research, or any long-running task in Claude Code.

---

## Who it's for

- 👩‍💻 **Developers** juggling long-lived projects who are tired of re-explaining context.
- 🔬 **Researchers & analysts** who want a durable, citable trail of decisions and rationale.
- 🤖 **AI agent builders** who need transparent, inspectable, file-based agent memory.
- 🗂️ **Anyone** who wants their AI's memory to be *theirs* — plain text, on disk, forever.

---

## Contributing

Issues and PRs welcome. milepost is intentionally small and hackable — the entire behavior lives in one policy file, three command prompts, and five short hook scripts.

## License

[MIT](./LICENSE) © Saša Mitrović

---

<div align="center">

**milepost** · persistent, plain-markdown, milestone-triggered memory for Claude Code.
If it saves you from re-explaining your project one more time, give it a ⭐.

</div>
