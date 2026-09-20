#!/usr/bin/env python3
"""Prefix each workspace's label with the digit `switch_workspace` uses.

herdr's server assigns every workspace a `number`, and prefix+shift+N jumps to
it. Nothing in the sidebar shows that number, so this puts it in the label.

It used to write an `$idx` metadata token into `[ui.sidebar.spaces]` rows
instead. herdr-radar owns those rows now and regenerates them, so the label --
which radar renders through its `workspace` token -- is the only place a number
survives. That is also why this no longer runs from `tab_bar_right`: radar owns
that key too. A launchd agent drives it instead.

Only 1..9 are prefixed; those are the only digits the binding can reach.

Base names are remembered in STATE so a reorder re-prefixes the original name
rather than stacking digits. If that file is lost, a leading "<digit> " is
stripped defensively -- which would eat a real leading digit from a name like
"3 musketeers", judged the better failure than a label growing a digit per run.
"""

import json
import os
import pathlib
import re
import subprocess
import sys

HERDR = os.environ.get("HERDR_BIN", "herdr")
STATE = pathlib.Path.home() / ".local/state/herdr-sidebar-index/base-labels.json"
PREFIX = re.compile(r"^[1-9] ")


def herdr(*args):
    return subprocess.run([HERDR, *args], capture_output=True, text=True, timeout=10)


def main():
    listing = herdr("workspace", "list")
    if listing.returncode != 0:
        return
    try:
        spaces = json.loads(listing.stdout)["result"]["workspaces"]
    except (ValueError, KeyError):
        return

    try:
        base = json.loads(STATE.read_text())
    except (OSError, ValueError):
        base = {}

    for w in spaces:
        wid, label, num = w["workspace_id"], w.get("label") or "", w.get("number", 0)
        # First sighting: the label is pristine unless STATE was lost, hence the strip.
        name = base.get(wid) or PREFIX.sub("", label)
        base[wid] = name
        want = f"{num} {name}" if 1 <= num <= 9 else name
        if want != label:
            herdr("workspace", "rename", wid, want)

    # Drop workspaces that no longer exist, then persist.
    base = {k: v for k, v in base.items() if k in {w["workspace_id"] for w in spaces}}
    try:
        STATE.parent.mkdir(parents=True, exist_ok=True)
        STATE.write_text(json.dumps(base, indent=2) + "\n")
    except OSError:
        pass


if __name__ == "__main__":
    try:
        main()
    except Exception:
        sys.exit(0)
