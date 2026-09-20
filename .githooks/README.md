# Git hooks

Enabled with `git config core.hooksPath .githooks`, which `scripts/install.sh`
does for you and which `scripts/doctor.sh` checks.

| Hook | What it does |
| --- | --- |
| `pre-commit` | Runs `scripts/scan-secrets.sh` over the staged files. A finding aborts the commit. |

The hook scans the staging area rather than the working tree, because the tree
can hold work in progress and the commit cannot.
