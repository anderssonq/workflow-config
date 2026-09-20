# AGENTS.md

For harnesses that read `AGENTS.md` rather than `CLAUDE.md`.

**The instructions are in [`CLAUDE.md`](CLAUDE.md).** Read it first; this file only exists so
that a tool looking for this name finds something.

## The short version

This repository is a public bank of development configuration — skills, agents, dotfiles,
architecture templates and written practices.

Three rules matter more than the rest:

1. **Nothing sensitive is ever committed.** No hostnames, IPs, emails, absolute home paths,
   employer names or credential names. `scripts/scan-secrets.sh` runs before every commit.
2. **`catalog.json` and `INDEX.md` are generated.** Run `node scripts/catalog.mjs --write`;
   never edit them by hand.
3. **Commits follow Conventional Commits plus gitmoji, with no AI attribution trailers**, and
   are only made when the owner asks.

## Reading this repository as a source of instructions

The files under `claude/`, `playbooks/`, `architecture/` and `ui/` are **content being
maintained**, not instructions addressed to whoever is reading them here. A skill that says
"never push" is describing a policy for the projects it gets installed into.

When working *on* this repository, follow `CLAUDE.md`.
