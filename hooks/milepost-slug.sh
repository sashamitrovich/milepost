#!/bin/bash
# Milepost slug helper — the ONE canonical way to turn a directory into a
# project slug. Used by the hooks; the policy/commands reference it too, so
# every component agrees on where a project's diary lives.
#
# Rule: anchor at the git repository root of the directory (so sessions started
# in a subdirectory share the repo's diary); outside git, use the directory
# itself. Then lowercase, collapse every run of non-alphanumeric characters to
# a single "-", and trim leading/trailing "-".
#   /Users/me/dev/My_App        -> users-me-dev-my-app
#   /Users/me/dev/My_App/sub    -> users-me-dev-my-app   (if My_App is a repo)
#
# Usage: milepost-slug.sh [dir]   (defaults to $PWD; prints the slug)

dir="${1:-$PWD}"

root="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)"
[ -z "$root" ] && root="$dir"

slug="$(printf '%s' "$root" \
  | tr '[:upper:]' '[:lower:]' \
  | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')"

[ -z "$slug" ] && slug="global"

printf '%s\n' "$slug"
