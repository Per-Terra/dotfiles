#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
OS="$(uname -s)"

info()  { printf '\033[1;34m[info]\033[0m  %s\n' "$1"; }
warn()  { printf '\033[1;33m[warn]\033[0m  %s\n' "$1"; }
error() { printf '\033[1;31m[error]\033[0m %s\n' "$1" >&2; exit 1; }

install_stow() {
  if command -v stow &>/dev/null; then
    info "stow already installed"
    return
  fi

  info "Installing stow..."
  case "$OS" in
    Darwin)
      command -v brew &>/dev/null || error "Homebrew not found. Install it first: https://brew.sh"
      brew install stow
      ;;
    Linux)
      if command -v apt-get &>/dev/null; then
        sudo apt-get update && sudo apt-get install -y stow
      elif command -v dnf &>/dev/null; then
        sudo dnf install -y stow
      elif command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm stow
      else
        error "No supported package manager found. Install stow manually."
      fi
      ;;
    *) error "Unsupported OS: $OS" ;;
  esac
}

COMMON_PACKAGES=(zsh sheldon git ssh ghostty tmux)
MACOS_PACKAGES=(cmux karabiner)

stow_packages() {
  local packages=("${COMMON_PACKAGES[@]}")
  if [[ "$OS" == "Darwin" ]]; then
    packages+=("${MACOS_PACKAGES[@]}")
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

create_dirs() {
  mkdir -p "$HOME/.ssh/cm"
  chmod 700 "$HOME/.ssh" 2>/dev/null || true
  chmod 700 "$HOME/.ssh/cm" 2>/dev/null || true
}

create_local_configs() {
  if [[ ! -f "$HOME/.config/git/config.local" ]]; then
    mkdir -p "$HOME/.config/git"
    warn "Created empty ~/.config/git/config.local — add your signingkey and allowedSignersFile"
    cat > "$HOME/.config/git/config.local" << 'EOF'
# Machine-specific git settings
# [user]
# 	signingkey = <your signing key>
# [gpg "ssh"]
# 	allowedSignersFile = ~/.ssh/allowedSigners
EOF
  fi

  if [[ ! -f "$HOME/.ssh/config.local" ]]; then
    warn "Created empty ~/.ssh/config.local — add your host definitions"
    cat > "$HOME/.ssh/config.local" << 'EOF'
# Machine-specific SSH host definitions
EOF
  fi
}

install_tpm() {
  local tpm_dir="$HOME/.config/tmux/plugins/tpm"
  if [[ ! -d "$tpm_dir" ]]; then
    info "Installing tmux plugin manager (tpm)..."
    git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
  fi
}

brew_bundle() {
  if [[ "$OS" == "Darwin" ]] && command -v brew &>/dev/null && [[ -f "$DOTFILES_DIR/Brewfile" ]]; then
    read -p "Run 'brew bundle' to install Brewfile packages? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      info "Running brew bundle..."
      brew bundle --file="$DOTFILES_DIR/Brewfile"
    fi
  fi
}

check_zsh() {
  if [[ "$OS" == "Linux" ]] && ! command -v zsh &>/dev/null; then
    warn "zsh is not installed. Install it with: sudo apt install zsh"
    warn "Then set it as default: chsh -s \$(which zsh)"
  fi
}

main() {
  info "Dotfiles installer — OS: $OS"
  echo

  install_stow
  create_dirs
  create_local_configs
  stow_packages
  install_tpm
  brew_bundle
  check_zsh

  echo
  info "Done! Restart your shell to apply changes."
  if command -v tmux &>/dev/null; then
    info "Run tmux and press prefix + I to install tmux plugins."
  fi
}

main "$@"
