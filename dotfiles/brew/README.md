# Homebrew

```bash
brew bundle --file=dotfiles/brew/Brewfile          # install everything
brew bundle check --file=dotfiles/brew/Brewfile    # what is missing
```

## Curated, not dumped

`brew bundle dump` emits the whole dependency closure — 101 formulae on this machine — and
every one of them looks equally deliberate. The `Brewfile` here is the list of things
installed **on purpose**, grouped by why, so that a year from now the answer to "do I still
need fontforge" is in the file.

Dependencies come back automatically. Nothing is lost by leaving them out.

## Not in here, on purpose

- **Node** arrives through `nvm`, so a project's `.nvmrc` decides rather than the machine.
  `pnpm` comes from `corepack`, pinned per repository by `packageManager`.
- **Rust** arrives through `rustup`, for the same reason.
- Anything installed once for a single project and never used again.

## The two entries that are easy to miss

**`gnu-sed`.** BSD `sed -i` requires an argument; GNU's does not. Any script written on Linux
that edits in place fails on macOS in a way that looks like a syntax error. Having it
installed does not fix that by itself — it gives you `gsed` to reach for.

**A Nerd Font.** The prompt theme and the editor's icon set both assume one. Without it,
every status line renders as boxes, which reads as a broken configuration rather than a
missing font.
