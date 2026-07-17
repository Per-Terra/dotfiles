# Set XDG base directories
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# Set ZDOTDIR to use XDG_CONFIG_HOME for zsh configuration
export ZDOTDIR="$XDG_CONFIG_HOME"/zsh

# Skip eager compinit in Ubuntu's /etc/zsh/zshrc (compinit is run in deferred.zsh)
skip_global_compinit=1

# Node (nvm) — non-interactive shell でも PATH を通す
export NVM_DIR="$XDG_CONFIG_HOME"/nvm
[ -d "$NVM_DIR/versions/node" ] && export PATH="$(ls -d "$NVM_DIR"/versions/node/*/bin 2>/dev/null | head -1):$PATH"

# 非対話シェルでも PATH を通す(重い初期化・補完は deferred.zsh で遅延読込み)
# pnpm (Performant Node.js package manager)
export PNPM_HOME="$XDG_DATA_HOME"/pnpm
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac

# deno
export DENO_INSTALL="$HOME/.deno"
case ":$PATH:" in
  *":$DENO_INSTALL/bin:"*) ;;
  *) export PATH="$DENO_INSTALL/bin:$PATH" ;;
esac

# bun
export BUN_INSTALL="$HOME/.bun"
case ":$PATH:" in
  *":$BUN_INSTALL/bin:"*) ;;
  *) export PATH="$BUN_INSTALL/bin:$PATH" ;;
esac

# uv, sheldon, bat 等のバイナリ置き場
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$PATH:$HOME/.local/bin" ;;
esac

# Set SSH_AUTH_SOCK for Bitwarden SSH agent (macOS only)
if [[ "$OSTYPE" == darwin* ]]; then
  export SSH_AUTH_SOCK="$HOME"/Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock
fi