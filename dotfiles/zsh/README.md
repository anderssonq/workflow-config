# zsh

| File | Goes to | Loaded |
| --- | --- | --- |
| `zshenv` | `~/.zshenv` | **Always** — login, interactive and scripts |
| `zprofile` | `~/.zprofile` | Once per login shell, before `.zshrc` |
| `zshrc` | `~/.zshrc` | Interactive shells only |
| `secrets.example.zsh` | `~/.secrets` (after filling in) | Sourced by `.zshrc` if present |

## The split, and why it matters

- **`.zshenv`** holds environment variables and nothing else. No aliases, no prompt, no
  output. It runs for every non-interactive script too, and anything that prints there breaks
  `scp`, `rsync` and anything that parses a remote shell's output.
- **`.zprofile`** initialises tools once per login: Homebrew's shell environment, version
  managers, `JAVA_HOME`.
- **`.zshrc`** is the interactive surface: theme, plugins, aliases.

Getting this wrong is invisible until something remote fails for no apparent reason.

## Prerequisites

oh-my-zsh, plus four plugins it does not bundle:

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}
git clone https://github.com/zsh-users/zsh-autosuggestions      "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
git clone https://github.com/zsh-users/zsh-syntax-highlighting  "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
git clone https://github.com/zdharma-continuum/fast-syntax-highlighting "$ZSH_CUSTOM/plugins/fast-syntax-highlighting"
git clone https://github.com/marlonrichert/zsh-autocomplete     "$ZSH_CUSTOM/plugins/zsh-autocomplete"
```

The `agnoster` theme wants a Nerd Font. `dotfiles/brew/Brewfile` installs two.

## What was changed on the way in

Three machine-specific things were parameterised, because a dotfiles repo that only works on
one machine is a backup, not a configuration:

- `JAVA_HOME` now resolves through `/usr/libexec/java_home` instead of a pinned JDK path.
- The Google Cloud SDK is found through `GCLOUD_SDK_DIR`, defaulting to `~/google-cloud-sdk`.
- Every optional toolchain is guarded, so a machine without Deno or LM Studio still gets a
  working shell instead of an error on every prompt.

**`~/.secrets` is not in this repository and never will be.** Only the example is.
