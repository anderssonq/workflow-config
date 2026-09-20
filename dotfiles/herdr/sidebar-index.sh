#!/usr/bin/env python3
"""Mirror herdr's jump indices into `$idx` sidebar tokens.

Spaces get the server-assigned workspace `number`, which is exactly the digit
`switch_workspace` (prefix+shift+N) uses. That mapping is authoritative.

Agents get their position in the snapshot's `agents` array. The server exposes
no agent number -- `focus_agent` (prefix+alt+N) indexes the rows the client
draws -- so this is inferred, not reported. Set AGENT_INDEX = False to drop it.

Only 1..9 are written; those are the only digits the bindings can reach.

This reconciles against the tokens already in the snapshot rather than against
a cached copy of its own last run, so it is self-healing: it clears tokens left
on panes that no longer host an agent, and rewrites tokens that were dropped
out from under it by a server restart or a session restore.

Run on an interval by the `tab_bar_right` command entry in config.toml.
Prints nothing, so that tab bar entry stays empty and invisible.
"""

import json
import os
import subprocess
import sys

SOURCE = "herdr-index"
TOKEN = "idx"
AGENT_INDEX = True
HERDR = os.environ.get("HERDR_BIN", "herdr")


def herdr(*args):
    return subprocess.run([HERDR, *args], capture_output=True, text=True, timeout=10)


def reconcile(kind, entries, desired):
    """Write only the tokens that differ from what the snapshot already shows."""
    for e in entries:
        key = e[f"{kind}_id"]
        want = desired.get(key, 0)
        want = str(want) if 1 <= want <= 9 else None
        have = (e.get("tokens") or {}).get(TOKEN)
        if want == have:
            continue
        if want is None:
            herdr(kind, "report-metadata", key, "--source", SOURCE, "--clear-token", TOKEN)
        else:
            herdr(kind, "report-metadata", key, "--source", SOURCE, "--token", f"{TOKEN}={want}")


def main():
    snap = herdr("api", "snapshot")
    if snap.returncode != 0:
        return
    try:
        data = json.loads(snap.stdout)["result"]["snapshot"]
    except (ValueError, KeyError):
        return

    workspaces = data.get("workspaces", [])
    reconcile("workspace", workspaces, {w["workspace_id"]: w.get("number", 0) for w in workspaces})

    # Every pane is reconciled, not just the ones hosting agents: a pane that
    # lost its agent has to have its stale number cleared, and it can only be
    # named here because it is absent from the `agents` array.
    panes = data.get("panes", [])
    agents = {}
    if AGENT_INDEX:
        agents = {a["pane_id"]: i for i, a in enumerate(data.get("agents", []), 1)}
    reconcile("pane", panes, agents)


if __name__ == "__main__":
    try:
        main()
    except Exception:
        sys.exit(0)
