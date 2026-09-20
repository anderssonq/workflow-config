# herdr

Terminal multiplexer, Neovim-first and agent-aware.

| File | Goes to |
| --- | --- |
| `config.toml` | `~/.config/herdr/config.toml` |
| `sidebar-index.sh` | `~/.config/herdr/sidebar-index.sh` |
| `dev.herdr.sidebar-index.plist.template` | Rendered into `~/Library/LaunchAgents/` by `install.sh` |

The config is worth reading even if you never use herdr: **every binding carries the reason
it is that binding**, and the reasons are all about not stealing keys from Neovim.

## The decisions

**Prefix is `ctrl+space`.** `ctrl+b` is scroll-page-up in Neovim. `ctrl+a` is
increment-number. `ctrl+space` is free in a stock configuration, which is the whole
requirement.

**Pane focus is prefix-first** (`prefix+h/j/k/l`), so bare `<C-h/j/k/l>` stays with Neovim's
own window navigation. Resize uses `ctrl+shift+alt+<arrow>` for the same reason: Neovim does
not bind that chord, so it can be direct and needs no mode.

**`shell_mode = "auto"`** gives login shells on macOS, so `~/.zprofile` runs and `PATH` is
what you expect inside every pane.

**`status_indicators = "symbols"`** — shape *and* colour, never colour alone.

## herdr-radar

[hhdebb/herdr-radar](https://github.com/hhdebb/herdr-radar) (MIT) turns the Agents sidebar
into something readable: a vendor logo and colour per agent, states that persist until you
look at them, worktrees nested under their repository, rows ordered by activity, and
light/dark following the desktop.

```bash
herdr plugin install hhdebb/herdr-radar --yes
```

Then **restart the terminal fully — Cmd+Q, not a new window.** The plugin installs an icon
font, and a running terminal will not pick up a font that was installed under it. If the
sidebar still does not change, start the daemon once:

```bash
herdr plugin action invoke hhdebb.herdr-radar.state-start
```

### What radar owns, and why none of it is committed

Radar writes managed blocks fenced by `# >>> herdr-radar … # <<<` markers and owns these
outright:

- `tab_bar_right` and `tab_bar_right_separator` in `[ui]`
- `[ui.sidebar.agents]`, `[ui.sidebar.agents.rows_by_agent]`, `[ui.sidebar.spaces]`
- `[theme.custom]` (it sets only `active_row_bg`), and it drives `[theme] name` and
  `auto_switch` from the desktop appearance

**Do not hand-write any of those.** If radar finds one declared outside its own markers it
refuses — `herdr: refused — … already written by hand; merge it yourself` — and changes
nothing. That is deliberate: TOML forbids declaring a table twice, and an unparseable
`config.toml` takes every plugin down with it. It never clobbers.

The committed `config.toml` here therefore contains **only the hand-written half**. Radar's
blocks are absent for two reasons, and the second is the one that decides it:

1. They are generated. Committing them means fighting the plugin on every machine.
2. The tab-bar block hardcodes an absolute path into the plugin's state directory —
   `/Users/<you>/.local/state/herdr/plugins/…`. Committing that would put a username in a
   public repository, and `scripts/scan-secrets.sh` refuses it.

So: install the plugin, let it write its own blocks, and leave them out of git.

### The two collisions, and how they were resolved

**`panel_bg = "reset"` was in `[theme.custom]`,** which radar owns. It moved to
`[theme.custom.light]` and `[theme.custom.dark]` — those subtables are *not* on radar's
managed list, and herdr layers them on top of whatever radar writes.

That is the general trick: **any chrome override you need to keep goes in a subtable radar
does not manage.**

**`tab_bar_right` used to run `sidebar-index.sh` every 5 seconds.** Radar owns that key now,
so the periodic work moved to a launchd job at a 10-second interval, rendered from
`dev.herdr.sidebar-index.plist.template`. If you need something on a timer alongside herdr,
that is the shape — `tab_bar_right` is no longer available for it.

```bash
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/dev.herdr.sidebar-index.plist
launchctl bootout   gui/$(id -u)/dev.herdr.sidebar-index          # to remove it
```

`install.sh` renders the file and prints the load command rather than running it: loading a
background job is a decision worth making on purpose.

## Workspace numbers, and why agents have none

`sidebar-index.sh` prefixes each workspace label with the digit `prefix+shift+N` jumps to,
taken from the server's authoritative workspace `number`. Base names are remembered in
`~/.local/state/herdr-sidebar-index/base-labels.json`, so reordering re-prefixes the original
name instead of stacking digits. Radar renders `$space_label` and `$group`, so the numbers
show through its rows.

**Do not rename workspaces by hand**, or you will be fighting that script.

**Agents are deliberately not numbered.** herdr exposes an authoritative `number` for
workspaces and tabs and none for agents: `focus_agent` (`prefix+alt+N`) indexes the rows the
*client* draws, which is client state and not in the API. Any agent index would be guesswork,
and a number that is wrong is worse than no number.

## `sidebar-index.sh` is Python

Despite the extension. herdr expects that exact filename, so it stays — but `bash -n` will
report a syntax error on it and be wrong. Check it with:

```bash
python3 -c 'import ast,sys; ast.parse(open(sys.argv[1]).read())' dotfiles/herdr/sidebar-index.sh
```

## What is deliberately not here

`session.json`, the sockets, the logs, the `.bak` files, and radar's generated blocks.
Runtime state, per-machine, and two of them are live file descriptors.

## Integration with everything else

herdr, the Neovim module that reports its AI columns, the Claude Code `SessionStart` hook in
[`../claude/`](../claude/) and the opencode TUI plugin are **one system**: each agent pane
reports which session owns it, and the sidebar shows what every agent is doing without
switching to it. Radar is what makes that readable at a glance.

Each piece is inert when herdr is not running, so none of them is a hard dependency.
