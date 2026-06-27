#!/bin/bash
# Milepost uninstaller — removes the plugin's global wiring.
# Leaves your diary data in ~/.claude/memory/milepost/ untouched.
set -uo pipefail

CLAUDE_DIR="$HOME/.claude"
COMMANDS_DIR="$CLAUDE_DIR/commands"
HOOKS_DIR="$CLAUDE_DIR/hooks"
SETTINGS="$CLAUDE_DIR/settings.json"
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
MARK_START="<!-- milepost:start -->"
MARK_END="<!-- milepost:end -->"
STAMP="$(date +%Y%m%d-%H%M%S)"

command -v jq >/dev/null 2>&1 || { echo "ERROR: jq is required."; exit 1; }

echo "Uninstalling milepost..."

# 1) Commands
rm -f "$COMMANDS_DIR/milepost.md" "$COMMANDS_DIR/status.md" "$COMMANDS_DIR/reflect.md"
echo "  ✓ commands removed"

# 2) Hook scripts
rm -f "$HOOKS_DIR/milepost-nudge.sh" "$HOOKS_DIR/milepost-session-start.sh"
echo "  ✓ hook scripts removed"

# 3) Remove policy block from CLAUDE.md (between markers)
if [ -f "$CLAUDE_MD" ] && grep -qF "$MARK_START" "$CLAUDE_MD"; then
  cp "$CLAUDE_MD" "$CLAUDE_MD.milepost-backup.$STAMP"
  awk -v s="$MARK_START" -v e="$MARK_END" '
    $0 ~ s {skip=1}
    skip==0 {print}
    $0 ~ e {skip=0}
  ' "$CLAUDE_MD" > "$CLAUDE_MD.tmp" && mv "$CLAUDE_MD.tmp" "$CLAUDE_MD"
  echo "  ✓ policy block removed from CLAUDE.md (backup: CLAUDE.md.milepost-backup.$STAMP)"
fi

# 4) Remove Stop hook entries referencing the script from settings.json
if [ -f "$SETTINGS" ] && grep -qF "milepost-nudge.sh" "$SETTINGS"; then
  cp "$SETTINGS" "$SETTINGS.milepost-backup.$STAMP"
  tmp="$(mktemp)"
  if jq '
      if .hooks.Stop then
        .hooks.Stop |= map(
          .hooks |= map(select((.command // "") | contains("milepost-nudge.sh") | not))
        )
        | .hooks.Stop |= map(select((.hooks | length) > 0))
        | if (.hooks.Stop | length) == 0 then del(.hooks.Stop) else . end
      else . end
    ' "$SETTINGS" > "$tmp"; then
    mv "$tmp" "$SETTINGS"
    echo "  ✓ Stop hook removed from settings.json (backup: settings.json.milepost-backup.$STAMP)"
  else
    rm -f "$tmp"
    echo "  ✗ failed to edit settings.json — left unchanged (backup saved)"
  fi
fi

# 5) Remove SessionStart hook entries referencing the script from settings.json
if [ -f "$SETTINGS" ] && grep -qF "milepost-session-start.sh" "$SETTINGS"; then
  cp "$SETTINGS" "$SETTINGS.milepost-backup.$STAMP" 2>/dev/null
  tmp="$(mktemp)"
  if jq '
      if .hooks.SessionStart then
        .hooks.SessionStart |= map(
          .hooks |= map(select((.command // "") | contains("milepost-session-start.sh") | not))
        )
        | .hooks.SessionStart |= map(select((.hooks | length) > 0))
        | if (.hooks.SessionStart | length) == 0 then del(.hooks.SessionStart) else . end
      else . end
    ' "$SETTINGS" > "$tmp"; then
    mv "$tmp" "$SETTINGS"
    echo "  ✓ SessionStart hook removed from settings.json"
  else
    rm -f "$tmp"
    echo "  ✗ failed to remove SessionStart hook from settings.json (left unchanged)"
  fi
fi

echo
echo "Done. Your diary data in ~/.claude/memory/milepost/ was left intact."
echo "Restart Claude Code to fully unload the hook."
