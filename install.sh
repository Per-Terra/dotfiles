#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
OS="$(uname -s)"

info()  { printf '\033[1;34m[info]\033[0m  %s\n' "$1"; }
warn()  { printf '\033[1;33m[warn]\033[0m  %s\n' "$1"; }
error() { printf '\033[1;31m[error]\033[0m %s\n' "$1" >&2; exit 1; }

has() { command -v "$1" &>/dev/null; }

# ---------------------------------------------------------------------------
# Tool installation
# ---------------------------------------------------------------------------

install_homebrew() {
  if has brew; then return; fi
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

install_prerequisites_darwin() {
  install_homebrew
  if [[ -f "$DOTFILES_DIR/Brewfile" ]]; then
    read -p "Run 'brew bundle' to install packages from Brewfile? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      info "Running brew bundle..."
      brew bundle --file="$DOTFILES_DIR/Brewfile"
    fi
  fi
}

install_prerequisites_linux() {
  info "Installing apt packages..."
  sudo apt-get update
  sudo apt-get install -y \
    zsh git stow tmux fzf zoxide bat curl wget unzip gnupg

  # bat is named batcat on Ubuntu — create symlink
  if has batcat && ! has bat; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(which batcat)" "$HOME/.local/bin/bat"
    info "Created bat -> batcat symlink"
  fi

  # eza: external apt repo
  if ! has eza; then
    info "Installing eza..."
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
    sudo apt-get update
    sudo apt-get install -y eza
  fi

  # gh (GitHub CLI): external apt repo
  if ! has gh; then
    info "Installing GitHub CLI..."
    sudo mkdir -p -m 755 /etc/apt/keyrings
    wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli-stable.list >/dev/null
    sudo apt-get update
    sudo apt-get install -y gh
  fi

  # sheldon: pre-built binary
  if ! has sheldon; then
    info "Installing sheldon..."
    curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh \
      | bash -s -- --repo rossmacarthur/sheldon --to "$HOME/.local/bin"
  fi

  # starship: official install script
  if ! has starship; then
    info "Installing starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- --yes
  fi

  # mise: official install script (on macOS it comes from the Brewfile)
  if ! has mise; then
    info "Installing mise..."
    curl -fsSL https://mise.run | sh
  fi
}

# Runtimes and dev CLIs declared in mise/.config/mise/config.toml, plus the
# global JS tools: pnpm for general ones, bun for ccstatusline (statusLine runs it with bun)
install_tools() {
  export PATH="${XDG_DATA_HOME:-$HOME/.local/share}/mise/shims:$HOME/.local/bin:$PATH"
  export PNPM_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/pnpm"
  export PATH="$PNPM_HOME/bin:$PATH"
  info "Installing mise tools..."
  mise install
  info "Installing global JS tools..."
  pnpm add -g defuddle
  bun add -g ccstatusline
}

# tmux plugin manager
install_tpm() {
  local tpm_dir="$HOME/.config/tmux/plugins/tpm"
  if [[ -d "$tpm_dir" ]]; then return; fi
  info "Installing tmux plugin manager (tpm)..."
  git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
}

# ---------------------------------------------------------------------------
# Stow
# ---------------------------------------------------------------------------

# Note: "gh" is the stow package for GitHub CLI config (~/.config/gh/config.yml),
# not the gh command itself (installed above via apt/brew).
COMMON_PACKAGES=(zsh sheldon git ssh ghostty tmux ccstatusline yt-dlp husky claude gh mise)
# "voice" starts the agy voice conversation on agent-host with this Mac's mic
MACOS_PACKAGES=(karabiner voice)
# "obsidian" is a WSL wrapper for the Windows Obsidian CLI (Obsidian.com)
LINUX_PACKAGES=(obsidian)

stow_packages() {
  local packages=("${COMMON_PACKAGES[@]}")
  if [[ "$OS" == "Darwin" ]]; then
    packages+=("${MACOS_PACKAGES[@]}")
  else
    packages+=("${LINUX_PACKAGES[@]}")
  fi

  info "Stowing packages: ${packages[*]}"
  cd "$DOTFILES_DIR"
  for pkg in "${packages[@]}"; do
    if [[ -d "$pkg" ]]; then
      info "  $pkg"
      stow -v -t "$HOME" "$pkg"
    else
      warn "  $pkg: directory not found, skipping"
    fi
  done
}

# ---------------------------------------------------------------------------
# Post-install setup
# ---------------------------------------------------------------------------

create_dirs() {
  mkdir -p "$HOME/.ssh/cm" "$HOME/.local/bin"
  chmod 700 "$HOME/.ssh" 2>/dev/null || true
  chmod 700 "$HOME/.ssh/cm" 2>/dev/null || true
}

create_local_configs() {
  if [[ ! -f "$HOME/.config/git/config.local" ]]; then
    mkdir -p "$HOME/.config/git"
    cat > "$HOME/.config/git/config.local" << 'EOF'
# Machine-specific git settings
# [user]
# 	signingkey = <your signing key>
# [gpg "ssh"]
# 	allowedSignersFile = ~/.ssh/allowedSigners
EOF
    warn "Created ~/.config/git/config.local — add your signingkey and allowedSignersFile"
  fi

  if [[ ! -f "$HOME/.ssh/config.local" ]]; then
    cat > "$HOME/.ssh/config.local" << 'EOF'
# Machine-specific SSH host definitions
EOF
    warn "Created ~/.ssh/config.local — add your host definitions"
  fi

  if [[ ! -f "$HOME/.config/zsh/.zshrc.local" ]]; then
    mkdir -p "$HOME/.config/zsh"
    cat > "$HOME/.config/zsh/.zshrc.local" << 'EOF'
# Machine-specific zsh settings (sourced at the end of .zshrc)
EOF
    warn "Created ~/.config/zsh/.zshrc.local — add machine-specific shell settings"
  fi
}

set_default_shell() {
  if [[ "$OS" == "Linux" ]] && [[ "$SHELL" != */zsh ]]; then
    warn "Default shell is not zsh. Run: chsh -s \$(which zsh)"
  fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
  info "Dotfiles installer — OS: $OS"
  echo

  case "$OS" in
    Darwin) install_prerequisites_darwin ;;
    Linux)  install_prerequisites_linux ;;
    *)      error "Unsupported OS: $OS" ;;
  esac

  create_dirs
  stow_packages
  create_local_configs
  install_tools
  install_tpm

  set_default_shell

  echo
  info "Done! Restart your shell to apply changes."
  info "Then run: tmux → prefix + I to install tmux plugins."
}

main "$@"
