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

# 1) Commands
cp "$SRC/commands/milepost.md" "$COMMANDS_DIR/"
cp "$SRC/commands/status.md"  "$COMMANDS_DIR/"
cp "$SRC/commands/reflect.md" "$COMMANDS_DIR/"
echo "  ✓ commands installed (/milepost, /status, /reflect)"

# 2) Hook scripts
cp "$SRC/hooks/milepost-nudge.sh" "$HOOKS_DIR/milepost-nudge.sh"
chmod +x "$HOOKS_DIR/milepost-nudge.sh"
cp "$SRC/hooks/milepost-session-start.sh" "$HOOKS_DIR/milepost-session-start.sh"
chmod +x "$HOOKS_DIR/milepost-session-start.sh"
echo "  ✓ hook scripts installed (nudge + session-start)"

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

echo
echo "Done. Restart Claude Code (or start a new session) to load the policy and hooks."
echo "Diaries will live in: $MEMORY_DIR/<project>/"
echo "Nudge interval: ${MILEPOST_NUDGE_INTERVAL:-900}s (set MILEPOST_NUDGE_INTERVAL to change)."
echo "To remove everything: bash \"$SRC/uninstall.sh\""
