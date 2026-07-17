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
    zsh git stow tmux fzf zoxide bat curl wget unzip

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

  # uv (Python)
  if ! has uv; then
    info "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
  fi

  # yt-dlp: config is stowed (COMMON_PACKAGES) so install the binary too
  if ! has yt-dlp; then
    info "Installing yt-dlp..."
    PATH="$HOME/.local/bin:$PATH" uv tool install yt-dlp
  fi

  # bun
  if ! has bun; then
    info "Installing bun..."
    curl -fsSL https://bun.com/install | bash
  fi

  # deno
  if ! has deno; then
    info "Installing deno..."
    curl -fsSL https://deno.land/install.sh | DENO_INSTALL="$HOME/.deno" sh
  fi

  # pnpm
  if ! has pnpm; then
    info "Installing pnpm..."
    curl -fsSL https://get.pnpm.io/install.sh | PNPM_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/pnpm" SHELL=/dev/null sh
  fi
}

# nvm: must NOT be installed via Homebrew
install_nvm() {
  local nvm_dir="${XDG_CONFIG_HOME:-$HOME/.config}/nvm"
  if [[ -s "$nvm_dir/nvm.sh" ]]; then return; fi
  info "Installing nvm..."
  mkdir -p "$nvm_dir"
  export NVM_DIR="$nvm_dir"
  PROFILE=/dev/null bash -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.6/install.sh | bash'
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
COMMON_PACKAGES=(zsh sheldon git ssh ghostty tmux ccstatusline yt-dlp husky claude gh)
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
  install_nvm
  install_tpm

  set_default_shell

  echo
  info "Done! Restart your shell to apply changes."
  info "Then run: tmux → prefix + I to install tmux plugins."
}

main "$@"
