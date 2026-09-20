#!/usr/bin/env bash
# Link the dotfiles and install the Claude Code bank on this machine.
#
#   scripts/install.sh              show what would happen, change nothing
#   scripts/install.sh --apply      do it
#   scripts/install.sh --apply --only zsh,git
#   scripts/install.sh --apply --brew
#
# Idempotent. Anything it replaces is backed up next to the original with a
# timestamp, because the worst outcome of a dotfiles installer is silently
# losing a configuration you had not committed yet.
set -euo pipefail

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
STAMP=$(date +%Y%m%d-%H%M%S)
APPLY=0
WITH_BREW=0
ONLY=''

while [ $# -gt 0 ]; do
  case "$1" in
    --apply) APPLY=1 ;;
    --brew)  WITH_BREW=1 ;;
    --only)  ONLY="${2:-}"; shift ;;
    -h|--help) sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) printf 'unknown option: %s\n' "$1" >&2; exit 2 ;;
  esac
  shift
done

# Machine- and account-specific values that must not be published.
# shellcheck source=/dev/null
[ -f "$REPO/dotfiles/local.env" ] && . "$REPO/dotfiles/local.env"

wants() { [ -z "$ONLY" ] || printf '%s' ",$ONLY," | grep -q ",$1,"; }
say()   { printf '  %s\n' "$*"; }
act()   { if [ "$APPLY" -eq 1 ]; then "$@"; else say "would: $*"; fi; }

backup() {
  local target=$1
  [ -e "$target" ] || [ -L "$target" ] || return 0
  # A symlink already pointing at us is not worth backing up.
  if [ -L "$target" ] && [ "$(readlink "$target")" = "$2" ]; then return 1; fi
  act mv "$target" "$target.backup-$STAMP"
  say "backed up $target -> $target.backup-$STAMP"
  return 0
}

link() {
  local src="$REPO/$1" dest=$2
  if [ ! -e "$src" ]; then say "SKIP (missing in repo): $1"; return; fi
  if ! backup "$dest" "$src"; then say "ok (already linked): $dest"; return; fi
  act mkdir -p "$(dirname "$dest")"
  act ln -s "$src" "$dest"
  say "linked $dest -> $1"
}

copy() {
  local src="$REPO/$1" dest=$2
  if [ ! -e "$src" ]; then say "SKIP (missing in repo): $1"; return; fi
  backup "$dest" "$src" || true
  act mkdir -p "$(dirname "$dest")"
  act cp -R "$src" "$dest"
  say "copied $dest <- $1"
}

[ "$APPLY" -eq 1 ] || printf '\nDRY RUN — nothing will change. Re-run with --apply.\n'

# ── brew ─────────────────────────────────────────────────────────────────
if wants brew && [ "$WITH_BREW" -eq 1 ]; then
  printf '\nHomebrew\n'
  if command -v brew >/dev/null 2>&1; then
    act brew bundle --file="$REPO/dotfiles/brew/Brewfile"
  else
    say 'brew not installed — see https://brew.sh, then re-run with --brew'
  fi
fi

# ── zsh ──────────────────────────────────────────────────────────────────
if wants zsh; then
  printf '\nzsh\n'
  link dotfiles/zsh/zshenv   "$HOME/.zshenv"
  link dotfiles/zsh/zprofile "$HOME/.zprofile"
  link dotfiles/zsh/zshrc    "$HOME/.zshrc"
  if [ ! -f "$HOME/.secrets" ]; then
    copy dotfiles/zsh/secrets.example.zsh "$HOME/.secrets"
    say 'created ~/.secrets from the example — fill it in, and never commit it'
  else
    say 'ok (left alone): ~/.secrets already exists'
  fi
fi

# ── git ──────────────────────────────────────────────────────────────────
if wants git; then
  printf '\ngit\n'
  link dotfiles/git/gitignore_global "$HOME/.gitignore_global"

  if [ -f "$HOME/.gitconfig" ] && grep -q '{{ GIT_NAME }}' "$HOME/.gitconfig" 2>/dev/null; then
    say '~/.gitconfig still has placeholders — rewriting'
    rm -f "$HOME/.gitconfig"
  fi

  if [ ! -f "$HOME/.gitconfig" ]; then
    # Identity is not configuration. Ask, rather than ship someone else's.
    if [ "$APPLY" -eq 1 ] && [ -t 0 ]; then
      read -r -p '  git user.name:  ' GIT_NAME
      read -r -p '  git user.email: ' GIT_EMAIL
      sed -e "s|{{ GIT_NAME }}|$GIT_NAME|" -e "s|{{ GIT_EMAIL }}|$GIT_EMAIL|" \
        "$REPO/dotfiles/git/gitconfig.template" > "$HOME/.gitconfig"
      say 'wrote ~/.gitconfig'
    else
      say 'would write ~/.gitconfig from the template (prompts for name and email)'
    fi
  else
    say 'ok (left alone): ~/.gitconfig already exists'
  fi
fi

# ── herdr ────────────────────────────────────────────────────────────────
if wants herdr; then
  printf '\nherdr\n'
  # config.toml is COPIED, not linked: herdr-radar writes its generated blocks
  # into this file. A symlink would send them into the repository, along with
  # the absolute path radar puts in its tab-bar block — and the secret gate
  # would then refuse every commit until someone worked out why.
  copy dotfiles/herdr/config.toml      "$HOME/.config/herdr/config.toml"
  link dotfiles/herdr/sidebar-index.sh "$HOME/.config/herdr/sidebar-index.sh"

  # The periodic sidebar-index run. It used to be a tab_bar_right entry until
  # herdr-radar took that key over. launchd expands neither ~ nor $HOME, so the
  # job description is rendered from a template rather than linked.
  JOB="$HOME/Library/LaunchAgents/dev.herdr.sidebar-index.plist"
  if [ "$APPLY" -eq 1 ]; then
    mkdir -p "$HOME/Library/LaunchAgents" "$HOME/.local/state/herdr-sidebar-index"
    sed "s|{{ HOME }}|$HOME|g" \
      "$REPO/dotfiles/herdr/dev.herdr.sidebar-index.plist.template" > "$JOB"
    say "wrote $JOB"
    say 'load it with:  launchctl bootstrap gui/$(id -u) "'"$JOB"'"'
  else
    say "would render $JOB from the template"
  fi

  # herdr-radar generates the config blocks this repo deliberately omits.
  if command -v herdr >/dev/null 2>&1; then
    # The daemon is not always up, so a miss here means "could not confirm",
    # not "not installed". Saying the second would send you to reinstall
    # something you already have.
    if herdr plugin list 2>/dev/null | grep -q 'hhdebb.herdr-radar'; then
      say 'ok (already installed): herdr-radar'
    else
      say 'herdr-radar not confirmed. If it is missing:'
      say '  herdr plugin install hhdebb/herdr-radar --yes'
      say '  then restart the terminal fully (Cmd+Q) so its icon font loads'
    fi
  else
    say 'herdr not on PATH — install it, then re-run with --only herdr'
  fi
fi

# ── claude ───────────────────────────────────────────────────────────────
if wants claude; then
  printf '\nClaude Code\n'
  # Settings and theme are copied rather than linked: the harness writes to
  # settings.json, and a symlink into the repo would turn every session into a
  # dirty working tree.
  copy dotfiles/claude/settings.json      "$HOME/.claude/settings.json"
  copy dotfiles/claude/daltonized-dark.json "$HOME/.claude/themes/daltonized-dark.json"

  # Skill shelves that belong at user level. project/ is per-project templates
  # and vendored/ is a lockfile, so neither is linked here.
  act mkdir -p "$HOME/.claude/skills"
  for shelf in meta core stack; do
    [ -d "$REPO/claude/skills/$shelf" ] || continue
    for dir in "$REPO/claude/skills/$shelf"/*/; do
      [ -d "$dir" ] || continue
      name=$(basename "$dir")
      link "claude/skills/$shelf/$name" "$HOME/.claude/skills/$name"
    done
  done

  # Agents and commands are single files.
  act mkdir -p "$HOME/.claude/agents"
  for family in zone role; do
    [ -d "$REPO/claude/agents/$family" ] || continue
    for f in "$REPO/claude/agents/$family"/*.md; do
      [ -f "$f" ] || continue
      link "claude/agents/$family/$(basename "$f")" "$HOME/.claude/agents/$(basename "$f")"
    done
  done

  act mkdir -p "$HOME/.claude/commands"
  for f in "$REPO/claude/commands"/*.md; do
    [ -f "$f" ] || continue
    case "$(basename "$f")" in README.md) continue ;; esac
    link "claude/commands/$(basename "$f")" "$HOME/.claude/commands/$(basename "$f")"
  done

  # Hooks are copied: they are executed by path, and a symlink into a repo the
  # harness does not know about is a support question waiting to happen.
  act mkdir -p "$HOME/.claude/hooks"
  for f in "$REPO/claude/hooks"/*.sh; do
    [ -f "$f" ] || continue
    copy "claude/hooks/$(basename "$f")" "$HOME/.claude/hooks/$(basename "$f")"
  done
fi

# ── editors ──────────────────────────────────────────────────────────────
if wants editors; then
  printf '\nEditors\n'
  copy dotfiles/editors/vscode/settings.json "$HOME/Library/Application Support/Code/User/settings.json"
  copy dotfiles/editors/cursor/settings.json "$HOME/Library/Application Support/Cursor/User/settings.json"
  copy dotfiles/editors/zed/settings.json    "$HOME/.config/zed/settings.json"
fi

# ── this repo's own hooks ────────────────────────────────────────────────
if wants self; then
  printf '\nThis repository\n'
  act git -C "$REPO" config core.hooksPath .githooks
  say 'pre-commit secret scan enabled'
fi

printf '\n'
if [ "$APPLY" -eq 1 ]; then
  printf 'Done. Run scripts/doctor.sh to check what landed.\n'
  printf 'Neovim is a separate repository — see dotfiles/nvim/README.md.\n'
else
  printf 'Dry run complete. Re-run with --apply.\n'
fi
