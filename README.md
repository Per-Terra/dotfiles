# dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).
Works on macOS and Linux (WSL2).

## Install

```sh
git clone https://github.com/Per-Terra/dotfiles.git ~/dev/dotfiles
cd ~/dev/dotfiles
./install.sh
```

The installer:

1. Installs prerequisites — Homebrew + Brewfile on macOS; apt packages plus
   eza, gh, sheldon, starship, uv, bun, deno, and pnpm on Linux
2. Stows the packages below into `$HOME`
3. Creates machine-local config stubs (see below)
4. Installs nvm and tpm (tmux plugin manager)

After installing, restart your shell. Inside tmux, press `prefix + I` to
install tmux plugins.

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

macOS only: `cmux`, `karabiner`.

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
