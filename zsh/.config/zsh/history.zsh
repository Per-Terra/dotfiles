[ -d "$XDG_STATE_HOME"/zsh ] || mkdir -p "$XDG_STATE_HOME"/zsh

# History parameters
HISTFILE="$XDG_STATE_HOME"/zsh/history
HISTSIZE=100000
SAVEHIST=100000

# History options
setopt EXTENDED_HISTORY      # コマンドの開始時刻と実行時間を保存
setopt HIST_IGNORE_ALL_DUPS  # 重複する古い履歴を削除
setopt HIST_IGNORE_DUPS      # 直前と同じコマンドを履歴に保存しない
setopt HIST_IGNORE_SPACE     # スペースで始まるコマンドを履歴に保存しない
setopt HIST_REDUCE_BLANKS    # 連続する空白を1つにまとめる
setopt HIST_VERIFY           # 履歴展開を含むコマンドは実行前に展開内容を表示
setopt SHARE_HISTORY         # 新しい履歴を読み込み、入力したコマンドは都度保存 (シェル間で履歴を共有)
