#!/bin/bash
# Milepost SessionStart hook.
# Surfaces the milestone diary for THE CURRENT PROJECT ONLY (matched via the
# canonical slug helper), plus a one-line index of the other tracked projects.
# Injecting every project's STATUS.md used to overflow the hook-output limit
# once a few projects existed, which silently broke recall — so it doesn't.
#
# If no diary exists yet for this project, it says so, which prompts diary
# creation at the first milestone instead of failing silently.
#
# Respects a `.no-milepost` file at the project root (opt-out: no recall, and
# the policy/nudge skip journaling too). Read-only: never writes to the diary.

MILEPOST_DIR="$HOME/.claude/memory/milepost"
SLUG_HELPER="$HOME/.claude/hooks/milepost-slug.sh"

input="$(cat)"
cwd="$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)"
[ -z "$cwd" ] && cwd="$PWD"

# Project root (for the opt-out check) mirrors the slug helper's anchoring.
root="$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)"
[ -z "$root" ] && root="$cwd"
[ -f "$root/.no-milepost" ] && exit 0

if [ -f "$SLUG_HELPER" ]; then
  slug="$(bash "$SLUG_HELPER" "$cwd" 2>/dev/null)"
else
  slug="$(printf '%s' "$root" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')"
fi
[ -z "$slug" ] && slug="global"

status_file="$MILEPOST_DIR/$slug/STATUS.md"

context="$(
  if [ -f "$status_file" ]; then
    echo "📔 Milepost diary — status of this project ($slug):"
    echo
    cat "$status_file"
    echo
    echo "(Full history: $MILEPOST_DIR/$slug/log.md)"
  else
    echo "📔 Milepost: no diary exists yet for this project (expected at $MILEPOST_DIR/$slug/). Per the Milepost policy, create log.md and STATUS.md there when the first milestone occurs."
  fi

  others="$(find "$MILEPOST_DIR" -mindepth 2 -maxdepth 2 -name STATUS.md 2>/dev/null \
    | sed 's|.*/\([^/]*\)/STATUS.md|\1|' | grep -vx "$slug" | sort | paste -sd ',' - | sed 's/,/, /g')"
  if [ -n "$others" ]; then
    echo
    echo "Other projects with milepost diaries (read their STATUS.md under $MILEPOST_DIR/<slug>/ on demand): $others"
  fi
)"

[ -z "$context" ] && exit 0

jq -nc --arg c "$context" \
  '{hookSpecificOutput:{hookEventName:"SessionStart", additionalContext:$c}}' 2>/dev/null \
  || printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":%s}}' "$(printf '%s' "$context" | jq -Rs .)"

exit 0
