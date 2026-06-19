#tmux
alias tm='tmux attach -t default || tmux new -s default'

# ls with eza
alias ls='eza --classify --icons --hyperlink --group-directories-first'
alias l='eza --classify --icons --hyperlink --group-directories-first --long --time-style=long-iso --binary --group --header --git --git-repos'
alias ll='eza --classify --icons --hyperlink --group-directories-first --long --time-style=long-iso --binary --group --header --git --git-repos'
alias la='eza --classify --icons --hyperlink --group-directories-first --long --time-style=long-iso --binary --group --header --git --git-repos --all'
alias lx='eza --classify --icons --hyperlink --group-directories-first --long --time-style=long-iso --binary --group --header --git --git-repos --all --extended --context'
alias lt='eza --classify --icons --hyperlink --group-directories-first --long --time-style=long-iso --binary --group --header --git --git-repos --all --tree --level=2'
alias tree='eza --classify --icons --hyperlink --group-directories-first --long --time-style=long-iso --binary --group --header --git --git-repos --all --tree --level=2'

# git
alias g='git'
alias gst='git status'
alias gco='git checkout'

# pnpm
alias pn='pnpm'
