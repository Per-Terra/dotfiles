function source {
  [[ -f "$1" ]] || { builtin source "$@"; return; }  # プロセス置換等はzcompile不可
  ensure_zcompiled $1
  builtin source $1
}
function ensure_zcompiled {
  local compiled="$1".zwc
  if [[ ! -r "$compiled" || "$1" -nt "$compiled" ]]; then
    echo "Compiling $1"
    zcompile $1
  fi
}
ensure_zcompiled "$ZDOTDIR"/.zshrc

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}"/sheldon
sheldon_cache="$cache_dir"/sheldon.zsh
sheldon_toml="${XDG_CONFIG_HOME:-$HOME/.config}"/sheldon/plugins.toml
if [[ ! -s "$sheldon_cache" || "$sheldon_toml" -nt "$sheldon_cache" ]] && (( $+commands[sheldon] )); then
  mkdir -p $cache_dir
  sheldon source > "$sheldon_cache.tmp" && mv "$sheldon_cache.tmp" "$sheldon_cache"
fi
[[ ! -s "$sheldon_cache" ]] || source "$sheldon_cache"
unset cache_dir sheldon_cache sheldon_toml

zsh-defer unfunction source

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# Machine-specific settings (not tracked by git)
[[ ! -f "$ZDOTDIR/.zshrc.local" ]] || source "$ZDOTDIR/.zshrc.local"
