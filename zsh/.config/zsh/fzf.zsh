# fzf options
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:500 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --icons --hyperlink --all --tree --color=always {} | head -100'"

# tmux integration
if [ -n "$TMUX" ]; then
  export FZF_TMUX=1
  export FZF_TMUX_OPTS='-p 80%'
  zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup  # fzf-tab integration
else
  unset FZF_TMUX
  unset FZF_TMUX_OPTS
  zstyle ':fzf-tab:*' fzf-command fzf  # fzf-tab integration
fi
