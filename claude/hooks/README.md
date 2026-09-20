# Hooks

Hooks are configured in `.claude/settings.json`, not discovered from a directory. The scripts
live here; the registration snippet is beside each one.

A hook is the right tool when something must happen **every time**, without the model
choosing to. "From now on, after every edit, check X" is a hook — it is not a memory and not
a preference, because the harness runs hooks and the model runs neither.

| Hook | Event | Does |
| --- | --- | --- |
| [`gate-on-stop`](gate-on-stop.sh) | `Stop` | Refuses to end the turn while the acceptance gate is red |
| [`sync-check`](sync-check.sh) | `PostToolUse` | Warns when two files that must mirror each other have drifted |

## Registering

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/sync-check.sh\"",
            "timeout": 30,
            "statusMessage": "Checking mirrored files"
          }
        ]
      }
    ]
  }
}
```

`$CLAUDE_PROJECT_DIR` is what makes a hook portable. **Never write an absolute path** into a
hook command — it is the single most common reason a shared config breaks on another machine.

## Writing one

- **Exit codes are the interface.** `0` passes. `2` blocks and feeds stderr back to the model.
  Anything else is an error that does not block.
- **Be fast.** A hook on `PostToolUse` runs after every edit. Two seconds becomes a minute
  across a session.
- **Fail open on infrastructure, closed on content.** If the tool the hook needs is missing,
  say so and exit `0`. If the check ran and found a problem, exit `2`.
- **Say what to do, not just what is wrong.** The model reads stderr and acts on it.
