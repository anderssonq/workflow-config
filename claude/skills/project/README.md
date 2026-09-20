# The project skill library

Eleven templates that install into a project's `.claude/skills/`. Nine are the core set; two
are added when the project needs them.

They are not generic advice. They are the shape that four unrelated projects — different
domains, different stacks, different sizes — independently converged on. The convergence is
the argument: these are the questions a project has to answer about itself before an agent
can work on it unsupervised.

## The core nine

| Skill | Answers |
| --- | --- |
| [`architecture-contract`](architecture-contract/SKILL.md) | What is load-bearing, and what breaks if you violate it |
| [`change-control`](change-control/SKILL.md) | How a change is classified, gated and closed |
| [`docs-and-writing`](docs-and-writing/SKILL.md) | Which document holds what, and how anything is superseded |
| [`failure-archaeology`](failure-archaeology/SKILL.md) | What was already tried, and why it lost |
| [`debugging-playbook`](debugging-playbook/SKILL.md) | It is broken — where do I look first |
| [`validation-and-qa`](validation-and-qa/SKILL.md) | What counts as proof |
| [`config-and-env`](config-and-env/SKILL.md) | Where each configuration value really comes from |
| [`build-run-and-operate`](build-run-and-operate/SKILL.md) | How it starts, runs and deploys |
| [`frontier`](frontier/SKILL.md) | What is worth building after the backlog |

## The two optional

| Skill | Add it when |
| --- | --- |
| [`diagnostics-and-tooling`](diagnostics-and-tooling/SKILL.md) | The project ships measurement scripts |
| [`domain-reference`](domain-reference/SKILL.md) | The domain has rules a model will get confidently wrong |

## Installing them

```bash
scripts/new-project.sh ./path/to/repo            # the core nine
scripts/new-project.sh ./path/to/repo --all      # plus the two optional
scripts/new-project.sh ./path/to/repo --prefix myapp   # myapp-architecture-contract, …
```

Use `--prefix` when the project also vendors third-party skills, so its own set is visibly
its own.

## Filling them in

Every template carries `<!-- FILL: … -->` markers. They are instructions, not placeholders to
leave behind: `scripts/doctor.sh` reports any that survive in an installed project.

Fill them in this order — each one's answers feed the next:

```
architecture-contract → change-control → validation-and-qa → build-run-and-operate
                     → config-and-env  → debugging-playbook → failure-archaeology
                     → docs-and-writing → frontier
```

Write `failure-archaeology` last of the factual ones and **do not leave it empty**. A project
with no recorded failures is a project whose failures are all still ahead of it, being
rediscovered one at a time.
