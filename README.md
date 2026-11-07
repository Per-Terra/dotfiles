# dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).
Works on macOS and Linux (WSL2).

## Install

```sh
git clone git@github.com:Per-Terra/dotfiles.git ~/dev/dotfiles
cd ~/dev/dotfiles
./install.sh
```

The installer:

1. Installs prerequisites — Homebrew + Brewfile on macOS (formulae, casks,
   App Store apps via `mas`, VS Code extensions); apt packages plus eza, gh,
   sheldon, starship, and mise on Linux
2. Stows the packages below into `$HOME`
3. Creates machine-local config stubs (see below)
4. Installs the mise tools (Node, Bun, pnpm, uv, Ruff, agy), the global
   JS tools (`defuddle` with pnpm, `ccstatusline` with bun), and tpm (tmux
   plugin manager)

After installing, restart your shell. Inside tmux, press `prefix + I` to
install tmux plugins. Sign in to the App Store before `brew bundle` so the
`mas` lines can install.

On macOS, run `./macos-defaults.sh` once and log in again to apply the
system settings (Dock, Finder, trackpad, keyboard).

To refresh the Brewfile after installing or removing something with Homebrew:
`brew bundle dump --force --file=~/dev/dotfiles/Brewfile`.

## Packages

Common (macOS and Linux):

| Package       | Contents                                             |
| ------------- | ---------------------------------------------------- |
| `zsh`         | `.zshenv`, `$ZDOTDIR` config (`~/.config/zsh`)       |
| `sheldon`     | zsh plugin manager config                            |
| `git`         | git config and global ignore                         |
| `ssh`         | SSH client config                                    |
| `ghostty`     | Ghostty terminal config                              |
| `tmux`        | tmux config (plugins are gitignored, managed by tpm) |
| `ccstatusline`| Claude Code status line (ccstatusline) settings      |
| `yt-dlp`      | yt-dlp config (cookie files are gitignored)          |
| `husky`       | global husky init                                    |
| `claude`      | Claude Code `~/.claude/settings.json`                |
| `gh`          | GitHub CLI config (`config.yml` only; `hosts.yml` credentials are never tracked) |
| `mise`        | mise global config: runtimes and dev CLIs            |

macOS only:

- `karabiner` — stowed as the whole `~/.config/karabiner` directory
  (Karabiner-Elements does not detect changes to a symlinked `karabiner.json`).
  `automatic_backups/` is gitignored. After stowing, run
  `launchctl kickstart -k gui/$(id -u)/org.pqrs.service.agent.Karabiner-Console-User-Server`
- `voice` — `~/.local/bin/voice`: starts the agy voice conversation
  (`~/secretary/tools/agy-voice` on agent-host) with this Mac's microphone and
  speakers. It runs `agy mic-serve`, forwards it to agent-host port 24713 over
  its own SSH connection, and opens a `voice` workspace in herdr's agent-host
  machine. Quitting agy closes the workspace and stops the forward; `voice stop`
  stops it by hand

Linux (WSL) only: `obsidian` — wrapper script (`~/.local/bin/obsidian`) for the
Windows Obsidian CLI (`Obsidian.com`); requires the Obsidian app to be running.

## Machine-local configuration

Machine-specific settings live in untracked `*.local` files, sourced or
included by the tracked configs:

- `~/.config/git/config.local` — included from git config; signing key,
  allowed signers, credential helpers
- `~/.ssh/config.local` — included from SSH config; host definitions
- `$ZDOTDIR/.zshrc.local` (`~/.config/zsh/.zshrc.local`) — sourced at the
  end of `.zshrc` if present

`install.sh` creates stubs for the first two; all are gitignored.
