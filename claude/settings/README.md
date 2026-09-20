# Settings profiles

Starting points for a project's `.claude/settings.json`. Copy one, then narrow it.

| Profile | For |
| --- | --- |
| [`base.json`](base.json) | Any repository. Read-only inspection, nothing that writes |
| [`node-app.json`](node-app.json) | A JavaScript or TypeScript project with a package manager |
| [`strict-deploy.json`](strict-deploy.json) | A repository where pushing the default branch deploys |

## Two files, two jobs

| File | Tracked | Holds |
| --- | --- | --- |
| `settings.json` | yes | What the whole team should have |
| `settings.local.json` | **no** | This machine's grants, this machine's paths |

Ignore the second globally, once, and you never think about it again:

```bash
echo '**/.claude/settings.local.json' >> ~/.config/git/ignore
```

## Granting permissions

**Grant the narrowest thing that works.** A run of exact commands ages better than one
wildcard: `Bash(pnpm lint *)` is a grant you can read; `Bash(*)` is a grant nobody can audit.

Health probes are worth granting verbatim, complete with their format strings, because they
recur every session and each variant is harmless:

```json
"Bash(curl -s -o /dev/null -w \"%{http_code}\\n\" http://localhost:3000/)"
```

**Never grant a path outside the repository.** A grant naming an absolute home path is a
grant that will not exist on the next machine, and it leaks a username into a tracked file.

## `soft_deny` — the rules that survive a helpful moment

Where the harness supports it, encode the project's own laws as denials rather than trusting
them to be remembered:

```json
"soft_deny": [
  "$defaults",
  "Bash(git push:*) — the owner pushes, never the agent",
  "Bash(git commit:*) without a prior yes — every commit needs explicit approval"
]
```

Each entry carries its reason in the string. A denial with no reason gets removed by whoever
next hits it.

**Do not put deployment topology in here.** Hostnames, repository names, credential names and
the shape of your production estate are not settings; they are a disclosure, and this file
gets shared.
