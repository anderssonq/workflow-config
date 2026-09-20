# herdr

Terminal multiplexer, Neovim-first and agent-aware. `config.toml` goes to
`~/.config/herdr/config.toml`; `sidebar-index.sh` beside it.

The file is worth reading even if you never use herdr: **every binding carries the reason it
is that binding**, and the reasons are all about not stealing keys from Neovim.

## The decisions

**Prefix is `ctrl+space`.** `ctrl+b` is scroll-page-up in Neovim. `ctrl+a` is
increment-number. `ctrl+space` is free in a stock configuration, which is the whole
requirement.

**Pane focus is prefix-first** (`prefix+h/j/k/l`), so bare `<C-h/j/k/l>` stays with Neovim's
own window navigation. Resize uses `ctrl+shift+alt+<arrow>` for the same reason: Neovim does
not bind that chord, so it can be a direct one without a mode.

**Plain keys only inside navigate mode**, which is modal and therefore safe.

**`kitty_graphics = true`** keeps image rendering working inside Neovim.

**`shell_mode = "auto"`** gives login shells on macOS, so `~/.zprofile` runs and `PATH` is
what you expect inside every pane.

**`status_indicators = "symbols"`** — shape *and* colour, never colour alone. Same reasoning
as the daltonised editor theme: a status you cannot distinguish is not a status.

## `sidebar-index.sh` is Python

Despite the extension. herdr expects that exact filename, so it stays — but `bash -n` will
report a syntax error on it and be wrong. Check it with `python3 -c 'import ast, sys;
ast.parse(open(sys.argv[1]).read())' dotfiles/herdr/sidebar-index.sh` instead.

It runs every five seconds from the tab bar and prints nothing, which is why it is invisible
in the UI: it reconciles the `$idx` tokens on spaces and agent panes. The space number comes
from the server and is authoritative; the agent index is inferred from the snapshot's array
position, because the server exposes no agent number.

## What is deliberately not here

`session.json`, the sockets, the logs and the `.bak` files. They are runtime state, they are
per-machine, and two of them are live file descriptors.

## Integration with everything else

herdr, the Neovim `core/herdr.lua` module, the Claude `SessionStart` hook in
[`../claude/`](../claude/) and the opencode TUI plugin are **one system**: each agent pane
reports which session owns it, and the sidebar shows what every agent is doing without
switching to it.

Each piece is inert when herdr is not running, so none of them is a dependency.
