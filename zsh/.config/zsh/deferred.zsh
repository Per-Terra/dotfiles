[ -d "$XDG_CACHE_HOME"/zsh ] || mkdir -p "$XDG_CACHE_HOME"/zsh

# Completion system cache
autoload -Uz compinit
compinit -d "$XDG_CACHE_HOME"/zsh/zcompdump
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME"/zsh/zcompcache

# zoxide (smarter cd command)
source <(zoxide init zsh)

# nvm (Node Version Manager)
export NVM_DIR="$XDG_CONFIG_HOME"/nvm
[ -s "$NVM_DIR"/nvm.sh ] && \. "$NVM_DIR"/nvm.sh  # This loads nvm
[ -s "$NVM_DIR"/bash_completion ] && \. "$NVM_DIR"/bash_completion  # This loads nvm bash_completion

# pnpm (Performant Node.js package manager)
export PNPM_HOME="$XDG_DATA_HOME"/pnpm
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# uv (Python package and project manager)
source <(uv generate-shell-completion zsh)
source <(uvx --generate-shell-completion zsh)
