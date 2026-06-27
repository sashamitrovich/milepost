#!/bin/bash
# Milepost periodic nudge — throttled Stop hook.
# Fires at end of each turn but stays silent unless enough time has passed,
# then injects a one-line reminder so milestone logging doesn't drift over a
# long session. The model decides whether anything is actually worth logging.
#
# Tunable: MILEPOST_NUDGE_INTERVAL (seconds, default 900 = 15 min).
# Never exits non-zero in a way that blocks stopping.

THRESHOLD_SECONDS="${MILEPOST_NUDGE_INTERVAL:-900}"

input="$(cat)"

cwd="$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)"
[ -z "$cwd" ] && cwd="$PWD"

# Stable per-project key for throttle state.
slug="$(printf '%s' "$cwd" | sed 's#[/ ]#-#g; s/^-*//')"
[ -z "$slug" ] && slug="global"

state_dir="$HOME/.claude/memory/milepost/.nudge-state"
mkdir -p "$state_dir" 2>/dev/null
state_file="$state_dir/$slug"

now="$(date +%s)"
last=0
[ -f "$state_file" ] && last="$(cat "$state_file" 2>/dev/null || echo 0)"
case "$last" in (*[!0-9]*|'') last=0 ;; esac

# Too soon since last nudge → stay quiet.
if [ "$(( now - last ))" -lt "$THRESHOLD_SECONDS" ]; then
  exit 0
fi

printf '%s' "$now" > "$state_file" 2>/dev/null

msg="[milepost reminder] If a meaningful milestone was reached recently (a deliverable completed, a key design decision, a blocker hit/resolved, a change of direction, or a material status change) and it is not yet recorded, append an entry to ~/.claude/memory/milepost/<project>/log.md and update STATUS.md per your Milepost policy. If nothing notable happened, do nothing and stop."

jq -nc --arg m "$msg" \
  '{hookSpecificOutput:{hookEventName:"Stop", additionalContext:$m}}' 2>/dev/null \
  || printf '{"hookSpecificOutput":{"hookEventName":"Stop","additionalContext":%s}}' "\"$msg\""

exit 0
