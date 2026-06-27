#!/bin/bash
# Milepost SessionStart hook.
# At the start of a session, surfaces the milestone diary — every tracked
# project's STATUS.md — into context, so prior work/status is always visible
# without having to ask. Read-only: it never writes to the diary.
#
# Output is injected via hookSpecificOutput.additionalContext. Stays silent
# (exits 0, no output) if there is no diary yet. Never blocks the session.

MILEPOST_DIR="$HOME/.claude/memory/milepost"

[ -d "$MILEPOST_DIR" ] || exit 0

statuses="$(find "$MILEPOST_DIR" -name "STATUS.md" 2>/dev/null | sort)"
[ -z "$statuses" ] && exit 0

context="$(
  echo "📔 Milepost diary — status of previous work across sessions:"
  echo
  while IFS= read -r status_file; do
    [ -z "$status_file" ] && continue
    project="$(basename "$(dirname "$status_file")")"
    echo "===== $project ====="
    cat "$status_file"
    echo
  done <<< "$statuses"
  echo "(Full per-project history is in each project's log.md under $MILEPOST_DIR)"
)"

[ -z "$context" ] && exit 0

jq -nc --arg c "$context" \
  '{hookSpecificOutput:{hookEventName:"SessionStart", additionalContext:$c}}' 2>/dev/null \
  || printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":%s}}' "$(printf '%s' "$context" | jq -Rs .)"

exit 0
