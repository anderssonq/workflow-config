# Claude Code — user level

| Copy | To |
| --- | --- |
| `settings.json` | `~/.claude/settings.json` |
| `daltonized-dark.json` | `~/.claude/themes/daltonized-dark.json` |

The skills and agents that go alongside these live in [`../../claude/`](../../claude/);
`scripts/install.sh` copies both.

## The theme

`dark-daltonized` as a base, deliberately. Colour-vision-safe defaults cost nothing when you
do not need them and are the difference between usable and not when you do — the same
reasoning as `status_indicators = "symbols"` in the herdr config.

## The three LSP plugins

TypeScript, Python and **Lua**. The third exists because the Neovim configuration is a real
Lua project with its own tests and CI, not a settings file.

## ⚠️ What was stripped, and why you should strip it too

The live version of this file has an `autoMode` block with two arrays. Both are gone here:

- **`soft_deny`** held project rules written as denials — good practice, and the strings name
  a private repository.
- **`environment`** described the production estate: two hostnames, the deploy platform,
  the auto-deploy-on-push behaviour, the default branch, and the **names** of the JWT, database
  and seed credentials.

None of that is a secret. Together it is **a map** — which is what actually leaks from a
public configuration repository. Credentials get noticed and rotated; topology gets published
and stays published.

If you keep an `autoMode` block, keep it in `settings.local.json`, which is ignored globally
by `../git/gitignore_global`.

The hook path also changed: the live file carries an absolute path containing a username.
`$HOME` works everywhere and leaks nothing.

## The hook

`herdr-agent-state.sh` is installed and owned by herdr — it reports which pane owns which
Claude session so the multiplexer's sidebar can show agent activity. It is not reproduced
here because herdr overwrites it on every update, and it is inert when herdr is not running.
