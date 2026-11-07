[ -d "$XDG_CACHE_HOME"/zsh ] || mkdir -p "$XDG_CACHE_HOME"/zsh

# Completion system cache
autoload -Uz compinit
compinit -d "$XDG_CACHE_HOME"/zsh/zcompdump
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME"/zsh/zcompcache

# zoxide (smarter cd command)
(( $+commands[zoxide] )) && builtin source <(zoxide init zsh)

# mise — 対話シェルではディレクトリごとの版と環境変数を効かせる（非対話の PATH は .zshenv の shims）
(( $+commands[mise] )) && builtin source <(mise activate zsh)

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
