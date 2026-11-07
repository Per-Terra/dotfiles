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
4. Installs the mise tools (`mise/.config/mise/config.toml`), the global
   JS tools (`defuddle` with pnpm, `ccstatusline` with bun), and tpm (tmux
   plugin manager)

After installing, restart your shell. Inside tmux, press `prefix + I` to
install tmux plugins. Sign in to the App Store before `brew bundle` so the
`mas` lines can install.

On macOS, run `./macos-defaults.sh` once and log in again to apply the
system settings (Dock, Finder, trackpad, keyboard).

To refresh the Brewfile after installing or removing something with Homebrew:
`brew bundle dump --force --file=~/dev/dotfiles/Brewfile`. The dump leaves out
casks installed outside Homebrew; keep the hand-added `gyazo` and `zoom`
lines (installed from their own installers on this Mac).

Apps installed by hand, with their own installers and updaters:

- Microsoft Word, Excel, PowerPoint (Microsoft AutoUpdate), Teams, OneDrive
- Adobe Acrobat DC
- DaVinci Resolve and Blackmagic Proxy Generator (Blackmagic Design)
- Homedale, MochiLog

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
- `mic` — `~/.local/bin/mic-serve-ensure`: lends this Mac's microphone and
  speakers to agy's voice mode on agent-host. The `agent-host` entry in the SSH
  config runs it as `LocalCommand` to start `agy mic-serve` (127.0.0.1:4713) if
  it is not running, and forwards it to agent-host port 24713 with
  `RemoteForward`. Any connection to agent-host, including herdr's, carries it;
  a second connection warns that the forward failed and connects without it.
  The first `agy mic-serve` asks for microphone access for the terminal app

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
