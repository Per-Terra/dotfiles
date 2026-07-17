[ -d "$XDG_CACHE_HOME"/zsh ] || mkdir -p "$XDG_CACHE_HOME"/zsh

# Completion system cache
autoload -Uz compinit
compinit -d "$XDG_CACHE_HOME"/zsh/zcompdump
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME"/zsh/zcompcache

# zoxide (smarter cd command)
(( $+commands[zoxide] )) && builtin source <(zoxide init zsh)

# nvm (Node Version Manager) — 初回実行時に遅延読み込み (node の PATH は .zshenv で設定済み)
nvm() {
  unfunction nvm
  [ -s "$NVM_DIR"/nvm.sh ] && \. "$NVM_DIR"/nvm.sh  # This loads nvm
  [ -s "$NVM_DIR"/bash_completion ] && \. "$NVM_DIR"/bash_completion  # This loads nvm bash_completion
  nvm "$@"
}

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

# Completions — 毎回の動的生成は遅いのでキャッシュし、バイナリ更新時のみ再生成
cache_completion() {
  local cache="$XDG_CACHE_HOME"/zsh/completions/_"$1"
  (( $+commands[$1] )) || return 0
  if [[ ! -s "$cache" || "$commands[$1]" -nt "$cache" ]]; then
    mkdir -p "${cache:h}"
    "${@:2}" > "$cache"
  fi
  builtin source "$cache"
}
cache_completion deno deno completions zsh
cache_completion uv uv generate-shell-completion zsh
cache_completion uvx uvx --generate-shell-completion zsh
unfunction cache_completion
