#!/usr/bin/env bash
# Public-repo gate. Exits non-zero if a tracked file carries something that
# should never leave this machine.
#
# Scope: git-tracked files only (plus anything passed as an argument), because
# an ignored file is not what gets published.
#
# Escape hatch: a line carrying the marker below is skipped. Use it for the
# places that must show a pattern in order to document it, and nowhere else.
set -uo pipefail

cd "$(git rev-parse --show-toplevel)" || exit 1

MARKER='allow-secret-pattern'
SELF='scripts/scan-secrets.sh'

NAMES=() REGEXES=() SKIPS=()
# rule <reported name> <regex> [skip-regex]
# The skip regex exempts values that match the shape but can never be sensitive:
# loopback addresses, documentation domains. Everything else is reported.
rule() { NAMES+=("$1"); REGEXES+=("$2"); SKIPS+=("${3:-}"); }

rule 'absolute home path'   '/Users/[A-Za-z0-9._-]+/'
rule 'email address'        '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' '@example\.(com|org)|noreply@|user@host'
rule 'IPv4 address'         '(^|[^0-9.])([0-9]{1,3}\.){3}[0-9]{1,3}([^0-9.]|$)' '127\.0\.0\.|0\.0\.0\.0|255\.255\.255'
rule 'npm auth token'       '_authToken'
# Editor and tool settings files are an under-watched credential store:
# extensions write tokens into them with no prompt. Generic on purpose — naming
# a vendor here would publish which vendor, which is the thing worth hiding.
rule 'vendored tool token'  '[A-Za-z][A-Za-z0-9_-]*\.(apiToken|apiKey|authToken|accessToken|organizationName|orgName)'
rule 'AWS access key'       'AKIA[0-9A-Z]{16}'
rule 'GitHub token'         'gh[pousr]_[A-Za-z0-9]{20,}'
rule 'OpenAI-style key'     'sk-[A-Za-z0-9]{20,}'
rule 'Slack token'          'xox[baprs]-[A-Za-z0-9-]{10,}'
rule 'JSON Web Token'       'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.'
rule 'private key block'    '-----BEGIN [A-Z ]*PRIVATE KEY-----'
rule 'assigned secret'      '(password|passwd|secret|api_?key|access_?token)[[:space:]]*[:=][[:space:]]*.?[A-Za-z0-9/+_-]{16,}'

# Names that must not be published cannot be written here, because this file is
# published. `.scan-denylist` is gitignored: one extended regex per line, blank
# lines and # comments skipped. Use it for private repository names, client
# names, internal service names — anything whose mere mention is the disclosure.
# See .scan-denylist.example.
DENYLIST="$(git rev-parse --show-toplevel)/.scan-denylist"
if [ -f "$DENYLIST" ]; then
  while IFS= read -r pattern; do
    case "$pattern" in ''|'#'*) continue ;; esac
    rule 'denylisted name' "$pattern"
  done < "$DENYLIST"
fi

if [ "$#" -gt 0 ]; then
  FILES=$(printf '%s\n' "$@")
else
  FILES=$(git ls-files)
fi

hits=0 scanned=0
while IFS= read -r file; do
  [ -f "$file" ] || continue
  [ "$file" = "$SELF" ] && continue
  case "$file" in *.png|*.jpg|*.jpeg|*.webp|*.gif|*.ico|*.pdf|*.zip|*.woff*|*.ttf) continue ;; esac
  scanned=$((scanned + 1))

  for i in "${!NAMES[@]}"; do
    while IFS= read -r match; do
      [ -z "$match" ] && continue
      lineno=${match%%:*}
      line=${match#*:}
      case "$line" in *"$MARKER"*) continue ;; esac
      if [ -n "${SKIPS[$i]}" ] && printf '%s' "$line" | grep -qE "${SKIPS[$i]}"; then continue; fi
      printf '  %s:%s  [%s]\n    %s\n' "$file" "$lineno" "${NAMES[$i]}" "$(printf '%s' "$line" | cut -c1-120)"
      hits=$((hits + 1))
    done < <(grep -nEI "${REGEXES[$i]}" "$file" 2>/dev/null)
  done
done <<< "$FILES"

if [ "$hits" -gt 0 ]; then
  printf '\nscan-secrets: %d finding(s). Nothing was committed.\n' "$hits" >&2
  printf 'Fix the line, or add the marker if it exists only to document the pattern.\n' >&2
  exit 1
fi

printf 'scan-secrets: clean (%d files).\n' "$scanned"
