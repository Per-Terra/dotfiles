# Set XDG base directories
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# Set ZDOTDIR to use XDG_CONFIG_HOME for zsh configuration
export ZDOTDIR="$XDG_CONFIG_HOME"/zsh

# Set SSH_AUTH_SOCK for Bitwarden SSH agent (macOS only)
if [[ "$OSTYPE" == darwin* ]]; then
  export SSH_AUTH_SOCK="$HOME"/Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock
fi
