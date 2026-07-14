#!/bin/bash
# Milepost secret guard — PreToolUse hook (matcher: Write|Edit|Bash).
# Mechanically blocks secret-shaped content from entering the diary, so the
# "never log secrets" policy doesn't depend on the model remembering it.
#
# Scope: only tool calls that touch ~/.claude/memory/milepost/ are inspected
# (Write/Edit by file_path; Bash by the command string mentioning the diary
# dir). Everything else passes through untouched — this hook never interferes
# with normal project work, and it fails OPEN on its own errors (jq missing,
# scanner missing) rather than breaking tool use.
#
# On a hit it DENIES the call with a reason instructing the model to rewrite
# the entry referencing secrets by location ("token in .ha_token"), never by
# value.

MILEPOST_DIR="$HOME/.claude/memory/milepost"
SCANNER="$HOME/.claude/hooks/milepost-secret-scan.sh"

input="$(cat)"

command -v jq >/dev/null 2>&1 || exit 0
[ -f "$SCANNER" ] || exit 0

tool="$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)"

text=""
case "$tool" in
  Write|Edit)
    file_path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)"
    case "$file_path" in
      "$MILEPOST_DIR"/*|~/.claude/memory/milepost/*) ;;
      *) exit 0 ;;
    esac
    text="$(printf '%s' "$input" | jq -r '(.tool_input.content // "") + "\n" + (.tool_input.new_string // "")' 2>/dev/null)"
    ;;
  Bash)
    cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)"
    case "$cmd" in
      *memory/milepost*) text="$cmd" ;;
      *) exit 0 ;;
    esac
    ;;
  *) exit 0 ;;
esac

[ -z "$text" ] && exit 0

hits="$(printf '%s' "$text" | bash "$SCANNER")" && exit 0

reason="Milepost secret guard: this write to the milestone diary contains secret-shaped content ($(printf '%s' "$hits" | tr '\n' ' ' | sed 's/ $//')). Diaries must NEVER contain credential values. Rewrite the entry so secrets are referenced by location only (e.g. 'token stored in .ha_token'), never by value, then retry."

jq -nc --arg r "$reason" \
  '{hookSpecificOutput:{hookEventName:"PreToolUse", permissionDecision:"deny", permissionDecisionReason:$r}}'

exit 0
