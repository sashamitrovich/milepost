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

```bash
git clone https://github.com/sashamitrovich/milepost.git
cd milepost && bash install.sh
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
- 🔒 **Privacy-first** — secrets and sensitive contents are summarized, never logged.
- ↩️ **Reversible & safe** — idempotent installer with automatic backups; clean uninstaller that keeps your data.

---

## Quick start

```bash
# 1. Clone
git clone https://github.com/sashamitrovich/milepost.git
cd milepost

# 2. Install (backs up & merges your ~/.claude config — never overwrites)
bash install.sh

# 3. Restart Claude Code, then just work. Claude journals milestones for you.
```

Remove it anytime — your diaries stay put:

```bash
bash uninstall.sh
```

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
No. The policy explicitly instructs Claude to summarize rather than record credentials, tokens, or sensitive file contents.

### Is it safe to install? Can I remove it cleanly?
Yes. The installer is idempotent, backs up `settings.json` and `CLAUDE.md` before editing, and merges rather than overwrites. `uninstall.sh` removes the wiring and leaves your diaries intact.

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

Issues and PRs welcome. milepost is intentionally small and hackable — the entire behavior lives in one policy file, three command prompts, and one short hook script.

## License

[MIT](./LICENSE) © Saša Mitrović

---

<div align="center">

**milepost** · persistent, plain-markdown, milestone-triggered memory for Claude Code.
If it saves you from re-explaining your project one more time, give it a ⭐.

</div>
