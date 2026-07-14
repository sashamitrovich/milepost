#!/bin/bash
# Milepost secret scanner — reads text on stdin and reports secret-shaped
# content. Shared by the PreToolUse guard hook (blocks bad diary writes) and
# usable manually to audit existing diaries:
#
#   bash milepost-secret-scan.sh < ~/.claude/memory/milepost/<proj>/log.md
#
# Exit 0 = clean, exit 1 = one or more patterns matched (names printed to
# stdout, one per line). Patterns favour precision over recall for known key
# formats, plus one deliberately-broad assignment pattern as a safety net —
# a false positive only makes the model rephrase, which is the safe direction.

input="$(cat)"
hits=""

check() { # name, extended-regex, [grep flags]
  local name="$1" re="$2" flags="${3:--E}"
  if printf '%s' "$input" | grep -q $flags -e "$re" 2>/dev/null; then
    hits="$hits$name\n"
  fi
}

check "private-key-block"   "-----BEGIN( [A-Z0-9]+)? PRIVATE KEY-----"
check "aws-access-key"      "AKIA[0-9A-Z]{16}"
check "github-token"        "(gh[pousr]|github_pat)_[A-Za-z0-9_]{20,}"
check "slack-token"         "xox[baprs]-[A-Za-z0-9-]{10,}"
check "google-api-key"      "AIza[0-9A-Za-z_-]{30,}"
check "sk-style-api-key"    "sk-[A-Za-z0-9_-]{20,}"
check "jwt"                 "eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\."
check "bearer-token"        "Bearer [A-Za-z0-9._=-]{20,}"
check "url-with-credentials" "[a-z][a-z0-9+.-]*://[^/@[:space:]]+:[^/@[:space:]]+@"
check "credential-assignment" \
  "(password|passwd|secret|api[_-]?key|access[_-]?token|auth[_-]?token|client[_-]?secret|private[_-]?key)[\"']?[[:space:]]*[:=][[:space:]]*[\"']?[A-Za-z0-9+/_.=-]{8,}" \
  "-Ei"

if [ -n "$hits" ]; then
  printf '%b' "$hits" | sort -u
  exit 1
fi
exit 0
