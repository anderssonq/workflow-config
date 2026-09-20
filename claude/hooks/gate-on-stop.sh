#!/usr/bin/env bash
# Stop hook: refuses to end the turn while the acceptance gate is red.
#
# Register on the "Stop" event. Exit 2 sends stderr back to the model, which
# then has to deal with the failure instead of handing back broken work.
#
# Set GATE_CMD in the environment, or edit the default below.
set -uo pipefail

cd "${CLAUDE_PROJECT_DIR:-$PWD}" || exit 0

GATE_CMD=${GATE_CMD:-}
if [ -z "$GATE_CMD" ]; then
  # Infer from the manifest, in order of preference.
  if   [ -f package.json ] && grep -q '"check"' package.json; then GATE_CMD='pnpm run check'
  elif [ -f package.json ] && grep -q '"lint"'  package.json; then GATE_CMD='pnpm lint && pnpm test'
  elif [ -f Makefile ]     && grep -q '^check:' Makefile;     then GATE_CMD='make check'
  else
    # Nothing to run is not a failure. Fail open on infrastructure.
    exit 0
  fi
fi

if ! output=$(eval "$GATE_CMD" 2>&1); then
  printf 'The acceptance gate is red. Fix it before ending the turn.\n\n' >&2
  printf '$ %s\n%s\n' "$GATE_CMD" "$(printf '%s' "$output" | tail -40)" >&2
  exit 2
fi
exit 0
