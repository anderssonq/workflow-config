# Terminal

There is not much here, and that is the point: **herdr is the terminal layer.** It owns the
panes, the tabs, the workspaces and the agent sidebar, so the host terminal emulator only has
to render text and get out of the way.

See [`../herdr/`](../herdr/).

## What the host terminal has to provide

- **A Nerd Font.** `dotfiles/brew/Brewfile` installs two.
- **`ctrl+space` must reach the application**, not be swallowed by the emulator. This is the
  one setting that breaks herdr, and the symptom — a prefix that silently does nothing — does
  not point at the cause.
- **Kitty graphics protocol**, if you want image rendering inside Neovim.
- **True colour.**

## Deliberately absent

No tmux configuration: herdr replaced it. No Ghostty, WezTerm, Alacritty or Kitty config —
the emulator is interchangeable once herdr is doing the work, which is a reasonable argument
for that arrangement.
