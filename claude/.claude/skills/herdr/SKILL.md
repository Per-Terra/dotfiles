---
name: herdr
description: "Control Herdr, a terminal multiplexer for coding agents: inspect and control panes, tabs, workspaces, commands, and other agents (start, prompt, wait for, read, and close them). Use it whenever it helps the task, without waiting for the user to mention Herdr — for example to delegate work to another agent, run and watch long commands, or check what other sessions are doing. Requires HERDR_ENV=1."
---

# Herdr

Herdr organizes terminals into workspaces, tabs, and panes, recognizes coding agents running inside panes, and exposes the current session through the `herdr` CLI.

Before anything else, verify that this agent is running inside a Herdr-managed pane:

```bash
test "${HERDR_ENV:-}" = 1
```

If the check fails, say that you are not running inside Herdr and stop. Do not inspect or control a Herdr session from outside Herdr.

If it passes, run `herdr --skill` and follow the instructions it prints. They match the installed version and are the authority on command syntax; do not rely on remembered syntax. If a project-level skill wraps Herdr for session management (for example a spawn or sessions skill), start and close agents through that skill rather than with raw `herdr` commands.
