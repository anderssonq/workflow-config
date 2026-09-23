#!/usr/bin/env bash
# Check that this machine — and optionally a project — got what it was supposed to.
#
#   scripts/doctor.sh                 check the machine and this repository
#   scripts/doctor.sh ../my-app       also check a project's installed skills
#
# Reports. Fixes nothing. Exit 1 if anything is wrong.
set -uo pipefail

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PROJECT=${1:-}
fails=0 warns=0

ok()   { printf '  \033[32m✓\033[0m %s\n' "$*"; }
bad()  { printf '  \033[31m✗\033[0m %s\n' "$*"; fails=$((fails + 1)); }
warn() { printf '  \033[33m!\033[0m %s\n' "$*"; warns=$((warns + 1)); }

linked() {
  local dest=$1 want="$REPO/$2"
  if [ ! -e "$dest" ]; then bad "missing: $dest"; return; fi
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$want" ]; then ok "$dest"; return; fi
  warn "$dest exists but is not linked to $2"
}

printf '\nRepository\n'
[ "$(git -C "$REPO" config core.hooksPath)" = ".githooks" ] \
  && ok 'pre-commit secret scan enabled' \
  || bad 'hooks not enabled — run: git config core.hooksPath .githooks'

if "$REPO/scripts/scan-secrets.sh" >/dev/null 2>&1; then ok 'no secrets in tracked files'
else bad 'scan-secrets found something — run scripts/scan-secrets.sh'; fi

if command -v node >/dev/null 2>&1; then
  if node "$REPO/scripts/catalog.mjs" >/dev/null 2>&1; then ok 'catalog up to date, skills within budget'
  else bad 'catalog stale or a skill is out of budget — run: node scripts/catalog.mjs'; fi
else
  warn 'node not installed — cannot verify the catalog'
fi

printf '\nDotfiles\n'
linked "$HOME/.zshenv"            dotfiles/zsh/zshenv
linked "$HOME/.zprofile"          dotfiles/zsh/zprofile
linked "$HOME/.zshrc"             dotfiles/zsh/zshrc
linked "$HOME/.gitignore_global"  dotfiles/git/gitignore_global
# Copied, not linked — radar writes into it. See install.sh for why.
[ -f "$HOME/.config/herdr/config.toml" ] \
  && ok '~/.config/herdr/config.toml' \
  || bad 'missing: ~/.config/herdr/config.toml'
if [ -L "$HOME/.config/herdr/config.toml" ]; then
  bad 'config.toml is a SYMLINK into the repo — radar will write its generated blocks, and their absolute path, into git'
fi

# herdr-radar generates config blocks this repo deliberately omits. A config
# with neither the plugin nor the blocks renders an unstyled sidebar, which
# looks like a broken install rather than a missing plugin.
if command -v herdr >/dev/null 2>&1; then
  if herdr plugin list 2>/dev/null | grep -q 'hhdebb.herdr-radar'; then
    ok 'herdr-radar installed'
  else
    warn 'herdr-radar not confirmed — herdr plugin install hhdebb/herdr-radar --yes'
  fi
fi
if grep -q 'herdr-radar' "$HOME/.config/herdr/config.toml" 2>/dev/null; then
  grep -q '# >>> herdr-radar' "$HOME/.config/herdr/config.toml" \
    && ok 'radar managed blocks present in config.toml' \
    || warn 'config.toml mentions radar but has no managed blocks — run the plugin once'
fi
RADAR_CFG="$HOME/.config/herdr/plugins/config/hhdebb.herdr-radar"
grep -q '^render_hook' "$RADAR_CFG/config.toml" 2>/dev/null \
  && [ -f "$RADAR_CFG/render-hook.js" ] \
  && ok 'radar render hook installed' \
  || warn 'radar render hook missing — workspaces and agents will have no numbers'
# The retired numbering job renames workspaces; with the hook also prefixing
# them, every label would carry two numbers.
[ -f "$HOME/Library/LaunchAgents/dev.herdr.sidebar-index.plist" ] \
  && warn 'retired sidebar-index job still installed — see dotfiles/herdr/README.md'

if [ -f "$HOME/.gitconfig" ]; then
  if grep -q '{{ GIT_' "$HOME/.gitconfig"; then bad '~/.gitconfig still has template placeholders'
  else ok '~/.gitconfig'; fi
else bad 'missing: ~/.gitconfig'; fi

if [ -f "$HOME/.secrets" ]; then
  ok '~/.secrets exists'
  # Names declared in the example that the real file does not define.
  while IFS= read -r key; do
    grep -q "^[[:space:]]*export $key=" "$HOME/.secrets" 2>/dev/null \
      || warn "~/.secrets does not define $key (declared in secrets.example.zsh)"
  done < <(grep -oE '^# export [A-Z_]+' "$REPO/dotfiles/zsh/secrets.example.zsh" 2>/dev/null | awk '{print $3}')
else
  bad 'missing: ~/.secrets — copy dotfiles/zsh/secrets.example.zsh'
fi

printf '\nClaude Code\n'
[ -f "$HOME/.claude/settings.json" ] && ok '~/.claude/settings.json' || bad 'missing: ~/.claude/settings.json'
if [ -f "$HOME/.claude/settings.json" ] && grep -q 'autoMode' "$HOME/.claude/settings.json"; then
  warn 'settings.json has an autoMode block — keep that in settings.local.json, it names infrastructure'
fi
for kind in skills agents commands; do
  n=$(find "$HOME/.claude/$kind" -maxdepth 1 -mindepth 1 2>/dev/null | wc -l | tr -d ' ')
  [ "${n:-0}" -gt 0 ] && ok "$n in ~/.claude/$kind" || warn "~/.claude/$kind is empty"
done

printf '\nToolchain\n'
for tool in git nvim node pnpm rg; do
  command -v "$tool" >/dev/null 2>&1 && ok "$tool $($tool --version 2>&1 | head -1 | tr -d '\n')" || warn "$tool not on PATH"
done
if command -v brew >/dev/null 2>&1; then
  brew bundle check --file="$REPO/dotfiles/brew/Brewfile" >/dev/null 2>&1 \
    && ok 'Brewfile satisfied' \
    || warn "Brewfile not satisfied — run: brew bundle --file=dotfiles/brew/Brewfile"
else
  warn 'brew not on PATH'
fi
# shellcheck source=/dev/null
[ -f "$REPO/dotfiles/local.env" ] && . "$REPO/dotfiles/local.env"
[ -f "$REPO/dotfiles/local.env" ] || warn 'dotfiles/local.env missing — copy local.env.example'
[ -d "$HOME/.config/nvim" ] && ok '~/.config/nvim present' || warn '~/.config/nvim missing — see dotfiles/nvim/README.md'

if [ -n "$PROJECT" ]; then
  printf '\nProject: %s\n' "$PROJECT"
  if [ ! -d "$PROJECT/.claude/skills" ]; then
    bad "no .claude/skills — run: scripts/new-project.sh $PROJECT"
  else
    n=$(find "$PROJECT/.claude/skills" -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' ')
    ok "$n skills installed"
    # FILL markers are instructions, not placeholders to leave behind.
    left=$(grep -rl 'FILL:' "$PROJECT/.claude/skills" 2>/dev/null | wc -l | tr -d ' ')
    if [ "${left:-0}" -gt 0 ]; then
      warn "$left skill(s) still carry FILL markers:"
      grep -rl 'FILL:' "$PROJECT/.claude/skills" 2>/dev/null \
        | sed "s|$PROJECT/.claude/skills/|      |" | sed 's|/SKILL.md||'
    else
      ok 'no FILL markers left'
    fi
    # A frontmatter name that does not match its directory silently never loads.
    while IFS= read -r f; do
      dir=$(basename "$(dirname "$f")")
      nm=$(grep -m1 '^name:' "$f" | sed 's/^name:[[:space:]]*//')
      [ "$nm" = "$dir" ] || bad "name \"$nm\" != directory \"$dir\" — that skill never loads"
    done < <(find "$PROJECT/.claude/skills" -name SKILL.md)
  fi
fi

printf '\n'
if [ "$fails" -gt 0 ]; then
  printf '%d problem(s), %d warning(s).\n' "$fails" "$warns"
  exit 1
fi
printf 'Healthy. %d warning(s).\n' "$warns"
