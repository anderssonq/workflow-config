# Scripts

| Script | Does | Safe by default |
| --- | --- | --- |
| [`install.sh`](install.sh) | Links the dotfiles, installs the bank into `~/.claude` | **Dry run** unless `--apply` |
| [`new-project.sh`](new-project.sh) | Installs the project skill library into a repository | Never overwrites |
| [`doctor.sh`](doctor.sh) | Reports what is missing, on the machine or in a project | Read-only |
| [`sync-skill.mjs`](sync-skill.mjs) | Fetches vendored skills, verifying their hashes | `--check` verifies without writing |
| [`catalog.mjs`](catalog.mjs) | Generates and verifies `catalog.json`, lints the skills | Verifies unless `--write` |
| [`scan-secrets.sh`](scan-secrets.sh) | The public-repo gate; runs as a pre-commit hook | Read-only |

## A new machine, end to end

```bash
git clone <this-repository> workflow-config
cd workflow-config

./scripts/install.sh                      # read what it would do
./scripts/install.sh --apply --brew       # do it
./scripts/doctor.sh                       # confirm

git clone "$NVIM_REPO" ~/.config/nvim   # NVIM_REPO from dotfiles/local.env
```

## A new project

```bash
./scripts/new-project.sh ../my-app --settings node-app --agents zone
./scripts/doctor.sh ../my-app             # counts the FILL markers left
```

## What `catalog.mjs` actually enforces

It is the linter for the authoring standard, and it fails the build on things that are
silent failures otherwise:

- **A skill whose frontmatter `name` differs from its directory.** That skill never loads,
  and nothing anywhere says so.
- A `description` over 35 words, or a `SKILL.md` over 350 lines.
- A skill with no "When NOT to use this skill" section — ambiguous routing is how two agents
  end up editing the same file.
- **An agent with no MUST NOT section.** An agent with capabilities and no boundary will
  eventually use all of them.
- A `catalog.json` that no longer matches the tree.

The first run of it against the skills inherited from this repo's own history found four
skills and four agents that did not meet the standard. That is what a linter is for.

## Conventions these scripts follow

- **Dry run is the default** for anything that writes outside the repository.
- **Nothing is overwritten without a backup** carrying a timestamp.
- **Exit codes are the interface**: `0` clean, non-zero with a reason on stderr.
- **Fail open on infrastructure, closed on content.** A missing tool is reported and skipped;
  a check that ran and found a problem fails.
