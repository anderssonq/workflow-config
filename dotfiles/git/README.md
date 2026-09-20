# git

| File | Goes to |
| --- | --- |
| `gitconfig.template` | `~/.gitconfig` — **fill in the two placeholders first** |
| `gitignore_global` | `~/.gitignore_global` |

```bash
git config --global core.excludesfile ~/.gitignore_global
```

## Why the config is a template

Name and email are identity, not configuration. A dotfiles repository that ships a filled-in
`[user]` block makes every cloner commit as its author until they notice — and they notice
after the first push.

`scripts/install.sh` prompts for both and writes the result.

## The one line that earns its place

```
**/.claude/settings.local.json
```

Ignored **globally**, once. That file accumulates machine-specific permission grants and
absolute paths that include a username, its name invites exactly that, and no per-project
`.gitignore` will reliably remember it. Decide it once at the machine level and stop thinking
about it.

## The settings worth knowing about

- **`pull.rebase = true`** — a pull never invents a merge commit. If the branch diverged,
  that is a fact worth seeing rather than papering over.
- **`rerere.enabled`** — git remembers how you resolved a conflict and replays it. It pays for
  itself the first time a rebase hits the same conflict twice, which is every rebase of any
  length.
- **`diff.colorMoved = zebra`** — moved code shows as moved rather than as a deletion next to
  an addition. It makes a refactor reviewable.
- **`fetch.prune`** — deleted remote branches stop haunting the local list.

## What was removed on the way in

Two absolute paths to a GUI merge tool, and the filled-in identity. Neither survives a move
to another machine, and one of them leaks a username.
