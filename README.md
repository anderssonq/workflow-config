# workflow-config

My bank of development configuration, skills and practices. Everything a new machine — or a
new project — needs in order to work the way I work.

Public on purpose, and carrying nothing sensitive: a hook checks every commit.

```bash
git clone <this-repository> workflow-config
cd workflow-config

./scripts/install.sh                   # shows what it would do, changes nothing
./scripts/install.sh --apply --brew    # does it
./scripts/doctor.sh                    # confirms what landed
```

And to install the method into a repository:

```bash
./scripts/new-project.sh ../my-app --settings node-app --agents zone
```

---

## What is here

| Directory | Is |
| --- | --- |
| [`claude/`](claude/) | Claude Code skills, agents, commands, hooks and settings |
| [`playbooks/`](playbooks/) | The practices, in prose. The reasoning everything else assumes |
| [`architecture/`](architecture/) | Monorepo, import boundaries, CI, containers — with the files beside them |
| [`ui/`](ui/) | Atomic design, tokens, component patterns, accessibility |
| [`dotfiles/`](dotfiles/) | zsh, git, brew, herdr, editors, user-level Claude Code |
| [`scripts/`](scripts/) | Install, scaffold, diagnose, sync, scan |

Full index: [`INDEX.md`](INDEX.md) to read, [`catalog.json`](catalog.json) for an agent to
parse. Both are generated from the tree, so neither can lie.

---

## Why it exists

The knowledge was spread across eight repositories and one machine's configuration. Pulling
it together turned up something I was not expecting:

> **Four separate projects had arrived at the same skill library, name for name.**

Four with nothing in common — different domains, different stacks, different sizes —
converged on the same nine questions: what is load-bearing, how a change is
controlled, what counts as proof, where each configuration value really comes from, how it
starts, what was already tried and lost, which document holds what, where to look when it
breaks, and what is worth building after the backlog.

That convergence is the argument. It is not one project's habit; these are the questions a
repository has to answer about itself before an agent can work in it unsupervised. They live
in [`claude/skills/project/`](claude/skills/project/README.md) as templates, and
`new-project.sh` installs them.

---

## The four rules that carry the most weight

If you read nothing else in [`playbooks/`](playbooks/):

1. **Never rewrite the working tree.** No `stash`, `checkout`, `restore` or `reset --hard`.
   Parallel sessions may be holding uncommitted work, and a stash destroys it with no trace
   at the point of loss.
2. **Never report something as working without running it.** The cost lands on whoever
   believes you.
3. **Never fan two agents onto the same files.** The second write silently wins.
4. **The request is consent for what it plainly asks**, and for nothing you noticed along
   the way.

---

## What is not here, and why

| Not here | Why |
| --- | --- |
| `~/.secrets` | Every API key on the machine. Only the `.example` travels, with the names |
| Neovim | Its own repository, cloned by URL from a gitignored `dotfiles/local.env`; a copy here would drift the day after, with nothing to signal it |
| Third-party skill bodies | Someone else's work under their own licence. The lockfile ships; `sync-skill.mjs` fetches them |
| Hostnames, IPs, absolute paths, account and project names | See below |

**What leaks from a configuration repository is almost never a credential** — those get
noticed and rotated. It is the topology: hostnames, the names of private repositories, the
deploy mechanism, server aliases, and the *names* of credentials. None of that is a secret.
Together it is a map, and a map does not get rotated after it is published.

That is why [`scripts/scan-secrets.sh`](scripts/scan-secrets.sh) runs in a pre-commit hook
instead of depending on anyone remembering. Names that cannot appear in the published rule
list — because the script itself is published — go in a gitignored `.scan-denylist`.

---

## Licence

MIT. See [`LICENSE`](LICENSE).
