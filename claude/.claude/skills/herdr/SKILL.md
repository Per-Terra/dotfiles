---
name: herdr
description: "Control Herdr, a terminal multiplexer for coding agents. Use only when the user explicitly mentions Herdr or asks to use Herdr to inspect or control panes, tabs, workspaces, commands, or another agent. Do not use merely because a task could benefit from a background terminal, delegation, or parallel work. Requires HERDR_ENV=1."
---

First check that `HERDR_ENV=1` is set. If it is not, stop and say that this agent is not running inside a Herdr-managed pane.

Then run `herdr --skill` and follow its output. It prints the full skill bundled with the installed herdr binary, so it always matches the running release.
