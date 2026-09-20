#!/usr/bin/env bash
# PostToolUse hook: warns when two files that must mirror each other drift apart.
#
# The case this exists for: a value that has to live in two places because the
# two sides must not import each other — a design token file and its copy in the
# app, a schema enum and its mirror in a shared package, a version in three
# manifests. A mirror with no check is a mirror that is already wrong.
#
# Register on Edit|Write|MultiEdit. Exits 2 on drift so the model sees it.
set -uo pipefail

cd "${CLAUDE_PROJECT_DIR:-$PWD}" || exit 0

# Each pair: "<path-a>:<path-b>". Add the project's own pairs here.
PAIRS=(
  # "design/tokens.css:src/styles/tokens.css"
)

[ ${#PAIRS[@]} -eq 0 ] && exit 0

drift=0
for pair in "${PAIRS[@]}"; do
  a=${pair%%:*}
  b=${pair##*:}
  # A missing side is a configuration problem, not drift. Fail open.
  [ -f "$a" ] && [ -f "$b" ] || continue
  if ! diff -q "$a" "$b" >/dev/null 2>&1; then
    printf '%s and %s have drifted.\n' "$a" "$b" >&2
    diff "$a" "$b" | head -20 >&2
    printf '\n' >&2
    drift=1
  fi
done

[ "$drift" -eq 1 ] && exit 2
exit 0
