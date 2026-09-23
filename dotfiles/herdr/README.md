# herdr

Terminal multiplexer, Neovim-first and agent-aware.

| File | Goes to |
| --- | --- |
| `config.toml` | `~/.config/herdr/config.toml` |
| `radar/config.toml` | `$(herdr plugin config-dir hhdebb.herdr-radar)/config.toml` |
| `radar/render-hook.js` | `$(herdr plugin config-dir hhdebb.herdr-radar)/render-hook.js` |

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

**`tab_bar_right` used to run a workspace-numbering script.** Radar owns that key now, and
the numbering moved into radar itself — see below. If you need something on a timer
alongside herdr, `tab_bar_right` is no longer available for it.

## Numbering

```
Spaces                  Agents
[1] Global              [1] Global
[2] api                   1 ~ Fix flaky retry test
[3] web                 [2] api
                          2 ~ Migrate invoices table
                          3 ~ Trace duplicate charges
```

`[N]` on a workspace is the index `prefix+shift+N` jumps to. `N ~` on an agent is the index
`prefix+alt+N` jumps to — its row position in the Agents panel, counted across groups, not
within one. The brackets are there because the workspace name doubles as the Agents panel's
group header, and a bare digit there would read as one more agent number.

Both come from radar's render hook, `radar/render-hook.js`, which radar calls just before it
publishes a row. **Nothing is renamed**: the prefixes exist only in what radar draws, so
renaming a workspace by hand is safe and the real label never carries a digit.

**The agent number is a reconstruction.** herdr exposes an authoritative `number` for
workspaces and tabs and none for agents: `focus_agent` indexes the rows the client draws. The
hook reproduces that order from the same sort radar installs on the panel — the `ws_key`,
`tab_key` and `sort_key` tokens radar writes, in the mode radar's flag says (`active`,
`recent`, or herdr's own order). It is right because radar owns the order, and only while it
does. Two consequences:

- Radar orders by activity, so **an agent's number moves** as other agents start working.
  The number is for the jump you make now, not a name to remember.
- The hook reads herdr at most every 1.5 seconds, so a row can show its previous number for
  that long after a reorder.

The hook is loaded once, when radar's daemon starts. After editing it:

```bash
herdr plugin action invoke hhdebb.herdr-radar.state-stop
herdr plugin action invoke hhdebb.herdr-radar.state-start
```

A hook that throws is treated as "no change" by radar, so a bug shows up as missing numbers,
never as a blank sidebar.

**Numbering used to be a launchd job** (`dev.herdr.sidebar-index`) that renamed every
workspace to carry its digit. On a machine that still has it, every label shows two numbers.
Remove it, then drop the digit it left on each label with `herdr workspace rename`:

```bash
launchctl bootout gui/$(id -u)/dev.herdr.sidebar-index
rm ~/Library/LaunchAgents/dev.herdr.sidebar-index.plist
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
