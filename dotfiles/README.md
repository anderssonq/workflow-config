# Dotfiles

The machine layer. `scripts/install.sh` links all of it; each directory's README says what
goes where if you would rather do it by hand.

| Directory | Is |
| --- | --- |
| [`zsh/`](zsh/) | The three-file shell split, and the secrets example |
| [`git/`](git/) | A templated `.gitconfig` and the global ignore file |
| [`brew/`](brew/) | A curated `Brewfile`, grouped by why each entry exists |
| [`herdr/`](herdr/) | The terminal multiplexer, its radar plugin, and the hook that numbers its rows |
| [`nvim/`](nvim/) | Why the Neovim config is its own repository, and how it gets cloned |
| [`claude/`](claude/) | User-level Claude Code settings and theme |
| [`editors/`](editors/) | VS Code, Cursor and Zed, sanitised |
| [`terminal/`](terminal/) | The short list of things the host emulator must provide |

## Install order

It matters in two places:

```
1. brew        the toolchain everything else assumes
2. zsh         needs Homebrew on PATH first
3. git         needs a name and an email — install.sh prompts
4. herdr, nvim, claude, editors     any order
```

## The system, not the files

These are not eight independent configurations. Four of them are one system:

**herdr** owns the panes and shows an agent sidebar. **Neovim** reports the state of its AI
columns to herdr. **Claude Code** reports which pane owns which session through a
`SessionStart` hook. **opencode** does the same through a TUI plugin.

The result is that a glance at the sidebar shows what every agent in every workspace is
doing, without switching to any of them. Each piece is inert when herdr is not running, so
none of them is a hard dependency — you can adopt one and skip the rest.

## What is deliberately not here

| Not here | Why |
| --- | --- |
| `~/.secrets` | Every API key on the machine. Only `zsh/secrets.example.zsh` ships |
| `dotfiles/local.env` | Machine- and account-specific values, such as which repository holds the Neovim config. Only the `.example` ships |
| `~/.ssh/` | Keys, and a host alias that names a real server |
| `~/.npmrc` | It holds a registry auth token |
| Neovim itself | Its own public repository; a copy here would drift silently |
| Sockets, logs, session files | Runtime state, per-machine, and two are live file descriptors |
| herdr-radar's generated config blocks | The plugin owns them, and one hardcodes an absolute path into its state directory |
| Anything with a hostname or an absolute home path | See the note below |

## The thing that actually leaks

Not credentials — those get noticed and rotated. **Topology.** Hostnames, repository names,
deploy mechanisms, server aliases, employer names, credential *names*, and absolute paths
carrying a username.

None of those is a secret. Together they are a map, and unlike a credential, a map does not
get rotated after it is published.

Two things were stripped on the way in for exactly this reason: an `autoMode` block naming
two production hosts and a deploy platform, and an editor settings file carrying an API token
and an organisation name. `scripts/scan-secrets.sh` runs before every commit so the next one
does not get through either.
