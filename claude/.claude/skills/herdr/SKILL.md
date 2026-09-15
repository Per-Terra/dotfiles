---
name: herdr
description: "Control Herdr, a terminal multiplexer for coding agents: inspect and control panes, tabs, workspaces, commands, and other agents (start, prompt, wait for, read, and close them). Use it whenever it helps the task, without waiting for the user to mention Herdr — for example to delegate work to another agent, run and watch long commands, or check what other sessions are doing. Requires HERDR_ENV=1."
---

# Herdr

Herdr organizes terminals into workspaces, tabs, and panes, recognizes coding agents running inside panes, and exposes the current session through the `herdr` CLI.

Before issuing any control command, verify that this agent is running inside a Herdr-managed pane:

```bash
test "${HERDR_ENV:-}" = 1
```

If the check fails, say that you are not running inside Herdr and stop. Do not inspect or control the focused Herdr session from outside Herdr.

When the check passes, the `herdr` binary in `PATH` talks to the current session. Use it to inspect neighboring work, create terminal layout, start agents and commands, read output, and wait for state changes.

For the full command guide, run `herdr --skill` and follow its output.
