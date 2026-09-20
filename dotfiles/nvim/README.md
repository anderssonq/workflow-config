# Neovim

**Not vendored here, on purpose.** The configuration is its own repository, with its own
licence, CI, installer and bundled fonts. A copy in this repository would start drifting the
day after it was made, and there would be no signal that it had.

```bash
# NVIM_REPO lives in dotfiles/local.env, which is gitignored.
git clone "$NVIM_REPO" ~/.config/nvim
nvim   # the plugin manager bootstraps itself from the committed lock file
```

## Why it is a separate repository

A Neovim configuration that has grown past a settings file is a **software project**: it has
modules, a plugin lock file, a health check, and behaviour that can regress. Treating it as
one — its own repository, its own CI, its own tests — is what makes it safe to change.

Treating it as a dotfile, vendored inside a dotfiles repository, gets you neither: no CI, no
history that means anything, and a copy that silently diverges from wherever you actually
edit it.

## What such a configuration looks like at maturity

The one this setup points at runs on a lazy-loading plugin manager with a committed lock
file, around fifty pinned plugins, and a colourscheme authored in-repo.

Its dominant theme is **de-plugin-ification**: roughly a third of its core modules exist to
replace a plugin with native Lua — inline git blame, symbol-occurrence highlighting, session
handling, indent guides, colour chips, TODO highlighting, the window picker, the markdown
reading view, plus a hand-rolled minimap and a couple of modals.

The reason is not minimalism for its own sake. Each of those plugins was a dependency with a
maintenance schedule, a startup cost and an API that could change under it. The replacements
are a few dozen lines each and never break on someone else's release day.

## Why it matters to this repository

It carries **the same skill-library architecture** as the other projects here — contract,
debugging playbook, failure archaeology, testing and QA, docs and style, frontier, name for
name — plus its own zone agents.

That is the evidence for
[`claude/skills/project/`](../../claude/skills/project/README.md) being a real pattern rather
than one project's habit: a text editor configuration and a backend API converged on the same
nine questions.

## What it shares with the rest of this setup

- A module reports the state of its AI columns to the herdr server, and is inert when herdr
  is not running.
- Its inline-completion module reads its API key **from the environment at request time** —
  the key lives in `~/.secrets`, never in the configuration.
- The `lua-lsp` plugin in [`../claude/settings.json`](../claude/settings.json) exists for it.
