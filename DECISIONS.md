# Decisions

Append-only. Newest at the bottom. Entries are superseded, never rewritten once committed —
an ADR edited to look smarter in hindsight stops being evidence of what was known at the time,
which is the only thing it is for.

Format and numbering rules:
[`playbooks/documentation-system.md`](playbooks/documentation-system.md).

## Index

| ADR | Title | Status |
| --- | --- | --- |
| [001](#adr-001--the-bank-is-organised-by-audience-not-by-tool) | The bank is organised by audience, not by tool | active |
| [002](#adr-002--the-project-skill-library-ships-as-templates-with-fill-markers) | The project skill library ships as templates with FILL markers | active |
| [003](#adr-003--catalogjson-and-indexmd-are-generated-and-linted) | catalog.json and INDEX.md are generated, and linted | active |
| [004](#adr-004--the-bank-is-not-symlinked-into-this-repositorys-own-claude) | The bank is not symlinked into this repository's own .claude | active |
| [005](#adr-005--vendored-skill-bodies-are-not-committed-and-hashes-are-recomputed) | Vendored skill bodies are not committed, and hashes are recomputed | active |
| [006](#adr-006--the-code-reviewer-scaffolding-is-deleted-rather-than-implemented) | The code-reviewer scaffolding is deleted rather than implemented | active |
| [007](#adr-007--neovim-stays-in-its-own-repository) | Neovim stays in its own repository | active |
| [008](#adr-008--vendored-entries-record-their-own-licence-and-legal-files-travel-with-them) | Vendored entries record their own licence, and legal files travel with them | active |
| [009](#adr-009--english-everywhere-enforced-by-the-linter) | English everywhere, enforced by the linter | active |
| [010](#adr-010--plugin-generated-config-is-not-committed-and-the-file-it-writes-is-copied-not-linked) | Plugin-generated config is not committed, and the file it writes is copied, not linked | active |

---

## ADR-001 — The bank is organised by audience, not by tool

- **Context:** the previous layout was a single `.claude/` directory holding five skills and
  four agents. Adding dotfiles, architecture templates and written practices to that shape
  would have produced one directory with six unrelated kinds of thing in it.
- **Decision:** six top-level directories by what the content is *for* — `claude/`,
  `playbooks/`, `architecture/`, `ui/`, `dotfiles/`, `scripts/` — each with a `README.md`
  index, plus a generated machine-readable catalog at the root.
- **Alternatives:** one `.claude/` with subdirectories (loses everything that is not a Claude
  artifact); numbered directories like `01-claude/` (ordering is not the useful axis);
  separate repositories per concern (four repositories to clone on a new machine).
- **Consequences:** an agent needs the catalog or a README to route, rather than inferring
  from a flat list. Revisit if the directory count passes eight — at that point the axis is
  probably wrong again.

## ADR-002 — The project skill library ships as templates with FILL markers

- **Context:** the nine-skill library is the most valuable thing here, and it is entirely
  project-specific content. Shipping one project's filled-in version would be shipping that
  project's private details; shipping empty headings would teach nothing.
- **Decision:** ship templates whose `<!-- FILL: … -->` markers are *instructions* describing
  what belongs there and, where it helps, a worked example of the shape. `doctor.sh` counts
  surviving markers in an installed project.
- **Alternatives:** a generator asking questions interactively (a wizard produces answers
  nobody believes); prose documentation only (does not install).
- **Consequences:** an installed-but-unfilled library looks finished from the outside, which
  is why `doctor.sh` reports the markers. Revisit if the markers routinely survive past the
  first month of a project.

## ADR-003 — catalog.json and INDEX.md are generated, and linted

- **Context:** 63 artifacts, and a hand-maintained index of that size is wrong within a
  month. A wrong index is worse than none, because an agent trusts it.
- **Decision:** `scripts/catalog.mjs` generates both from the tree and verifies them in CI
  and in `doctor.sh`. The same pass lints the authoring standard: frontmatter `name` matching
  the directory, description word count, file length, the presence of a "When NOT to use this
  skill" section, and a MUST NOT section on every agent.
- **Alternatives:** a hand-written index (drifts); no index (an agent has to walk the tree);
  linting as a separate script (two things to remember to run).
- **Consequences:** adding a skill means running `--write` in the same commit, enforced by
  the gate. The first run against the repository's own inherited files failed on eight of
  them, which is the argument for having it.

## ADR-004 — The bank is not symlinked into this repository's own .claude

- **Context:** the restructure plan called for `.claude/skills` and `.claude/agents` here to
  be symlinks into `claude/`, so the repository would use its own bank.
- **Decision:** do not. `scripts/install.sh` already links the bank into `~/.claude`, which
  is loaded in every session including sessions in this repository.
- **Alternatives:** the symlinks as planned — which would register every skill twice under
  the same name, once from user level and once from the project, and that is worse than not
  dogfooding.
- **Consequences:** working on this repository without having run `install.sh` gives no
  skills. Acceptable: the first thing anyone does here is run the installer. Revisit if
  project-level and user-level skills ever stop colliding by name.

## ADR-005 — Vendored skill bodies are not committed, and hashes are recomputed

- **Context:** two projects vendored the same five third-party skills, committing both the
  bodies and a `skills-lock.json`. The recorded `computedHash` values turned out not to be
  sha256 of the raw upstream files, so nothing could verify them. One entry had no `ref` at
  all.
- **Decision:** commit the lockfile, not the bodies. `scripts/sync-skill.mjs` fetches from
  `source` + `ref` and verifies against a hash that **is** sha256 of the raw file, reproducible
  with `curl … | shasum -a 256`. All five entries are pinned to a commit.
- **Alternatives:** keep the bodies (someone else's work under their own licence, drifting
  from upstream with nothing to signal it); keep the original hashes (they verify nothing);
  use a git submodule per skill (five submodules for five files).
- **Consequences:** a new machine needs network access before the vendored skills exist.
  `sync-skill.mjs --check` makes the gap visible rather than silent. The fetch covers the
  **whole skill directory**, not just its entry file — 101 files across the five entries —
  because two of these skills are an index plus a rule set, and fetching only `SKILL.md`
  would leave an index pointing at nothing. Verification is therefore two hashes: the entry
  file, and a manifest over every path and blob sha in the directory.

## ADR-006 — The code-reviewer scaffolding is deleted rather than implemented

- **Context:** the inherited `code-reviewer` skill shipped three Python scripts and three
  reference files. All three references were 103 lines of identical generic filler; all three
  scripts were the same 114-line skeleton whose `analyze()` was `# Main logic here` and always
  returned an empty finding list. `SKILL.md` documented them as working.
- **Decision:** delete all six and rewrite `SKILL.md` as what the skill actually is — a
  review prompt.
- **Alternatives:** implement them, which is a real project and a different one; leave them,
  which means shipping a public repository whose headline skill does not do what it says.
- **Consequences:** no automated analysis ships with the review skill. That was already true;
  it is now also visible.

## ADR-007 — Neovim stays in its own repository

- **Context:** the Neovim configuration is a large, mature, already-public repository with a
  licence, CI, an installer and bundled fonts.
- **Decision:** `dotfiles/nvim/` holds only a pointer and a note on what the configuration is.
- **Alternatives:** vendor a copy (drifts the day after, with nothing to signal it); a git
  submodule (a submodule for something that is already cloned to a fixed path by its own
  installer).
- **Consequences:** a new machine runs two clones instead of one. `doctor.sh` checks for
  `~/.config/nvim` and points at the README when it is missing.

## ADR-008 — Vendored entries record their own licence, and legal files travel with them

- **Context:** ADR-005 set up the vendored shelf when every entry was MIT, and the prose said
  so. Adding `impeccable` (Apache-2.0, with a `NOTICE.md`) made that claim false, and Apache
  section 4(d) requires the notice to travel with the work.
- **Decision:** the licence moves from prose into a `license` field on every lockfile entry.
  A `legalFiles` list names root files the licence requires alongside, and the sync fetches
  them into the skill directory. `UPSTREAM.md` renders source, ref, file count, licence and
  any `caution`. A `caution` string is surfaced on every fetch, not only in the file.
- **Alternatives:** keeping licences in the README (drifts, and already had); only vendoring
  permissive-and-similar licences (excludes the largest and most useful entry for no real
  reason); ignoring the notice requirement (not ours to ignore).
- **Consequences:** adding an entry means finding its licence first, which is the correct
  amount of friction. `impeccable` also carries a caution: its `scripts/impeccable` downloads
  and runs a self-contained binary on first use, the sync preserves its executable bit, and
  running it stays a decision rather than an accident. Revisit if an entry ever appears whose
  licence forbids redistribution — the fetch model already handles that, but the caution
  field would need to become a hard refusal.

## ADR-009 — English everywhere, enforced by the linter

- **Context:** the restructure plan deliberately kept the README cover in Spanish while
  everything else was English. That contradicted the house style rule this repository itself
  publishes — one language, everywhere — and it did not stop at the README: two shell
  dotfiles were copied from a machine with their Spanish comments intact, and the README's
  Spanish paragraph was also where a private repository name slipped through anonymisation.
- **Decision:** English in every tracked file — documentation, comments inside copied
  dotfiles, commit messages. `scripts/catalog.mjs` sweeps every tracked text file for a small
  set of high-precision Spanish function words and fails the gate on a hit.
- **Alternatives:** a bilingual README (two documents to keep in sync, and they will not be);
  Spanish for the cover only (what was tried, and it leaked past the cover); no check, just
  the rule (the rule existed and was broken anyway).
- **Consequences:** the detector is word-list based and therefore approximate. `todo` is
  excluded because it collides with `TODO`, and `del` because it is a Python keyword and this
  repository ships Python. A false positive is escaped with an `allow-spanish` marker on the
  line. Revisit if the marker is ever needed more than once — that would mean the word list
  is wrong rather than the file.

## ADR-010 — Plugin-generated config is not committed, and the file it writes is copied, not linked

- **Context:** herdr-radar renders the agent sidebar, and it does so by writing managed
  blocks into `~/.config/herdr/config.toml` between its own markers. It owns `tab_bar_right`,
  the three `[ui.sidebar.*]` tables and `[theme.custom]` outright, and refuses to run —
  changing nothing — if it finds any of them declared by hand outside its markers, because
  TOML forbids declaring a table twice and an unparseable config takes every plugin down.
- **Decision:** commit only the hand-written half of `config.toml`, with a comment where each
  managed block belongs saying what writes it and how to get it. Install by **copying** that
  file rather than symlinking it.
- **Alternatives:** committing the generated blocks (they hardcode an absolute path into the
  plugin's state directory, so the secret gate refuses them, and it means fighting the plugin
  on every machine); symlinking `config.toml` into the repository (the plugin then writes its
  generated blocks, and that absolute path, straight into git — the gate would start refusing
  every commit and the cause would not be obvious); not using the plugin.
- **Consequences:** a fresh machine gets an unstyled sidebar until the plugin runs once, so
  `doctor.sh` checks for both the plugin and the markers, and reports a symlinked
  `config.toml` as a defect. Two overrides had to move: `panel_bg` went from `[theme.custom]`
  to `[theme.custom.light]` and `[theme.custom.dark]`, which radar does not manage and herdr
  layers on top; and the five-second `sidebar-index.sh` run left `tab_bar_right` for a
  launchd job at ten seconds. Revisit if radar ever gains a way to declare overrides it will
  preserve — the subtable trick works, but it works by not being on a list.
