#!/bin/bash
# Milepost installer — wires the plugin into your global Claude Code config.
# Idempotent and reversible (see uninstall.sh). Backs up files it edits.
set -uo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
COMMANDS_DIR="$CLAUDE_DIR/commands"
HOOKS_DIR="$CLAUDE_DIR/hooks"
SETTINGS="$CLAUDE_DIR/settings.json"
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
MEMORY_DIR="$CLAUDE_DIR/memory/milepost"
MARK_START="<!-- milepost:start -->"
MARK_END="<!-- milepost:end -->"
STAMP="$(date +%Y%m%d-%H%M%S)"

command -v jq >/dev/null 2>&1 || { echo "ERROR: jq is required."; exit 1; }

echo "Installing milepost from: $SRC"
mkdir -p "$COMMANDS_DIR" "$HOOKS_DIR" "$MEMORY_DIR"

# Diaries are plaintext; keep them readable by the owner only.
chmod 700 "$MEMORY_DIR" "$CLAUDE_DIR/memory" 2>/dev/null
echo "  ✓ diary directory permissions restricted to owner (chmod 700)"

# 1) Commands
cp "$SRC/commands/milepost.md" "$COMMANDS_DIR/"
cp "$SRC/commands/status.md"  "$COMMANDS_DIR/"
cp "$SRC/commands/reflect.md" "$COMMANDS_DIR/"
echo "  ✓ commands installed (/milepost, /status, /reflect)"

# 2) Hook scripts
for h in milepost-nudge.sh milepost-session-start.sh milepost-slug.sh \
         milepost-secret-scan.sh milepost-secret-guard.sh; do
  cp "$SRC/hooks/$h" "$HOOKS_DIR/$h"
  chmod +x "$HOOKS_DIR/$h"
done
echo "  ✓ hook scripts installed (nudge, session-start, slug helper, secret scan + guard)"

# 3) Policy into global CLAUDE.md (idempotent, between markers)
[ -f "$CLAUDE_MD" ] || : > "$CLAUDE_MD"
if grep -qF "$MARK_START" "$CLAUDE_MD"; then
  echo "  • policy block already present in CLAUDE.md (left as-is)"
else
  cp "$CLAUDE_MD" "$CLAUDE_MD.milepost-backup.$STAMP" 2>/dev/null
  {
    printf '\n%s\n' "$MARK_START"
    cat "$SRC/policy/milepost-policy.md"
    printf '%s\n' "$MARK_END"
  } >> "$CLAUDE_MD"
  echo "  ✓ policy added to CLAUDE.md (backup: CLAUDE.md.milepost-backup.$STAMP)"
fi

# 4) Stop hook into settings.json (idempotent, merged not overwritten)
[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
if grep -qF "milepost-nudge.sh" "$SETTINGS"; then
  echo "  • Stop hook already present in settings.json (left as-is)"
else
  cp "$SETTINGS" "$SETTINGS.milepost-backup.$STAMP"
  tmp="$(mktemp)"
  if jq '.hooks.Stop = ((.hooks.Stop // []) + [{"matcher":"","hooks":[{"type":"command","command":"bash ~/.claude/hooks/milepost-nudge.sh"}]}])' \
        "$SETTINGS" > "$tmp"; then
    mv "$tmp" "$SETTINGS"
    echo "  ✓ Stop hook added to settings.json (backup: settings.json.milepost-backup.$STAMP)"
  else
    rm -f "$tmp"
    echo "  ✗ failed to edit settings.json — restoring backup"
    cp "$SETTINGS.milepost-backup.$STAMP" "$SETTINGS"
    exit 1
  fi
fi

# 5) SessionStart hook into settings.json (idempotent, merged not overwritten)
if grep -qF "milepost-session-start.sh" "$SETTINGS"; then
  echo "  • SessionStart hook already present in settings.json (left as-is)"
else
  cp "$SETTINGS" "$SETTINGS.milepost-backup.$STAMP" 2>/dev/null
  tmp="$(mktemp)"
  if jq '.hooks.SessionStart = ((.hooks.SessionStart // []) + [{"matcher":"","hooks":[{"type":"command","command":"bash ~/.claude/hooks/milepost-session-start.sh"}]}])' \
        "$SETTINGS" > "$tmp"; then
    mv "$tmp" "$SETTINGS"
    echo "  ✓ SessionStart hook added to settings.json"
  else
    rm -f "$tmp"
    echo "  ✗ failed to add SessionStart hook to settings.json (left unchanged)"
  fi
fi

# 6) PreToolUse secret guard into settings.json (idempotent, merged not overwritten).
#    Blocks secret-shaped content from being written into the diary.
if grep -qF "milepost-secret-guard.sh" "$SETTINGS"; then
  echo "  • PreToolUse secret guard already present in settings.json (left as-is)"
else
  cp "$SETTINGS" "$SETTINGS.milepost-backup.$STAMP" 2>/dev/null
  tmp="$(mktemp)"
  if jq '.hooks.PreToolUse = ((.hooks.PreToolUse // []) + [{"matcher":"Write|Edit|Bash","hooks":[{"type":"command","command":"bash ~/.claude/hooks/milepost-secret-guard.sh"}]}])' \
        "$SETTINGS" > "$tmp"; then
    mv "$tmp" "$SETTINGS"
    echo "  ✓ PreToolUse secret guard added to settings.json"
  else
    rm -f "$tmp"
    echo "  ✗ failed to add PreToolUse secret guard to settings.json (left unchanged)"
  fi
fi

# 7) Pre-approve diary writes so the user grants permission only once.
#    Scoped strictly to the milepost memory dir; uses ~/ so it's portable.
MP_RULES='["Edit(~/.claude/memory/milepost/**)","Write(~/.claude/memory/milepost/**)"]'
if grep -qF "memory/milepost/**" "$SETTINGS"; then
  echo "  • milepost write permissions already present in settings.json (left as-is)"
else
  cp "$SETTINGS" "$SETTINGS.milepost-backup.$STAMP" 2>/dev/null
  tmp="$(mktemp)"
  if jq --argjson rules "$MP_RULES" \
        '.permissions.allow = ((.permissions.allow // []) + $rules | unique)' \
        "$SETTINGS" > "$tmp"; then
    mv "$tmp" "$SETTINGS"
    echo "  ✓ milepost write permissions added to settings.json (granted once, no repeat prompts)"
  else
    rm -f "$tmp"
    echo "  ✗ failed to add milepost write permissions to settings.json (left unchanged)"
  fi
fi

echo
echo "Done. Restart Claude Code (or start a new session) to load the policy and hooks."
echo "Diaries will live in: $MEMORY_DIR/<project>/"
echo "Nudge interval: ${MILEPOST_NUDGE_INTERVAL:-900}s (set MILEPOST_NUDGE_INTERVAL to change)."
echo "To remove everything: bash \"$SRC/uninstall.sh\""
