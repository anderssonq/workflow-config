#!/usr/bin/env bash
# Install the project skill library into a repository.
#
#   scripts/new-project.sh ../my-app
#   scripts/new-project.sh ../my-app --all              include the two optional skills
#   scripts/new-project.sh ../my-app --prefix myapp     myapp-architecture-contract, …
#   scripts/new-project.sh ../my-app --agents zone      also install the zone agents
#   scripts/new-project.sh ../my-app --settings node-app
#
# Never overwrites. A skill that already exists is left alone and reported.
set -euo pipefail

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

CORE=(architecture-contract change-control docs-and-writing failure-archaeology
      debugging-playbook validation-and-qa config-and-env build-run-and-operate frontier)
OPTIONAL=(diagnostics-and-tooling domain-reference)

TARGET='' PREFIX='' AGENTS='' SETTINGS='' WITH_OPTIONAL=0

while [ $# -gt 0 ]; do
  case "$1" in
    --all)      WITH_OPTIONAL=1 ;;
    --prefix)   PREFIX="${2:-}"; shift ;;
    --agents)   AGENTS="${2:-}"; shift ;;
    --settings) SETTINGS="${2:-}"; shift ;;
    -h|--help)  sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*)         printf 'unknown option: %s\n' "$1" >&2; exit 2 ;;
    *)          TARGET="$1" ;;
  esac
  shift
done

[ -n "$TARGET" ] || { printf 'usage: new-project.sh <path-to-repo> [options]\n' >&2; exit 2; }
[ -d "$TARGET" ] || { printf 'not a directory: %s\n' "$TARGET" >&2; exit 1; }
TARGET=$(cd "$TARGET" && pwd)

SKILLS=("${CORE[@]}")
[ "$WITH_OPTIONAL" -eq 1 ] && SKILLS+=("${OPTIONAL[@]}")

mkdir -p "$TARGET/.claude/skills"
installed=0 skipped=0

for skill in "${SKILLS[@]}"; do
  name="$skill"
  [ -n "$PREFIX" ] && name="$PREFIX-$skill"
  dest="$TARGET/.claude/skills/$name"

  if [ -e "$dest" ]; then
    printf '  skip (exists)  %s\n' "$name"
    skipped=$((skipped + 1))
    continue
  fi

  mkdir -p "$dest"
  if [ -n "$PREFIX" ]; then
    # The frontmatter name must match the directory, or the skill silently
    # never loads. Rewrite it, and the sibling cross-references with it.
    sed -e "s|^name: $skill$|name: $name|" \
        -e "s|\.\./\([a-z-]*\)/SKILL\.md|../$PREFIX-\1/SKILL.md|g" \
        "$REPO/claude/skills/project/$skill/SKILL.md" > "$dest/SKILL.md"
  else
    cp "$REPO/claude/skills/project/$skill/SKILL.md" "$dest/SKILL.md"
  fi
  printf '  installed      %s\n' "$name"
  installed=$((installed + 1))
done

if [ -n "$AGENTS" ]; then
  mkdir -p "$TARGET/.claude/agents"
  for f in "$REPO/claude/agents/$AGENTS"/*.md; do
    [ -f "$f" ] || continue
    dest="$TARGET/.claude/agents/$(basename "$f")"
    if [ -e "$dest" ]; then printf '  skip (exists)  agent %s\n' "$(basename "$f")"; continue; fi
    cp "$f" "$dest"
    printf '  installed      agent %s\n' "$(basename "$f")"
  done
fi

if [ -n "$SETTINGS" ]; then
  src="$REPO/claude/settings/$SETTINGS.json"
  dest="$TARGET/.claude/settings.json"
  if [ ! -f "$src" ]; then
    printf '  no such profile: %s\n' "$SETTINGS" >&2
  elif [ -e "$dest" ]; then
    printf '  skip (exists)  settings.json\n'
  else
    cp "$src" "$dest"
    printf '  installed      settings.json (%s)\n' "$SETTINGS"
  fi
fi

cat <<SUMMARY

$installed installed, $skipped left alone, in $TARGET/.claude/

Next, in this order — each one's answers feed the next:

  architecture-contract  →  change-control  →  validation-and-qa
  build-run-and-operate  →  config-and-env  →  debugging-playbook
  failure-archaeology    →  docs-and-writing  →  frontier

Every template carries <!-- FILL: … --> markers. They are instructions, not
placeholders to leave behind — scripts/doctor.sh counts the survivors.

Do not leave failure-archaeology empty. A project with no recorded failures is
a project whose failures are all still ahead of it.
SUMMARY
