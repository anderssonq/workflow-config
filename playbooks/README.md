# Playbooks

The practices, in prose. Not prompts, not templates — the reasoning an agent or a person
needs in order to apply the rest of this repository without being told each time.

Every rule here has a cost attached that was actually paid. Where a rule exists because
something broke, the breakage is named.

| Playbook | Read it when |
| --- | --- |
| [`git-and-commits`](git-and-commits.md) | Before committing anything, and before touching the working tree |
| [`definition-of-done`](definition-of-done.md) | Deciding whether something is finished |
| [`verification-bar`](verification-bar.md) | About to claim something works |
| [`delegation-and-orchestration`](delegation-and-orchestration.md) | Deciding whether to hand work to a subagent |
| [`documentation-system`](documentation-system.md) | Writing or restructuring documents of record |
| [`failure-archaeology`](failure-archaeology.md) | Setting up a project's record of its own dead ends |
| [`security-baseline`](security-baseline.md) | Exposing a surface, adding a dependency, or handling a secret |

## The four that matter most

If you read nothing else here:

1. **Never rewrite the working tree.** Parallel sessions share it, and a stash destroys
   someone's work with no trace at the point of loss.
2. **Never report something as working without running it.** The cost lands on whoever
   trusts the report.
3. **Never fan two agents onto the same files.** The second write silently wins.
4. **The request is consent for what it plainly asks**, and for nothing you noticed along
   the way.
