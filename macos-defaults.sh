#!/usr/bin/env bash
# macOS の設定（Dock・Finder・トラックパッド・キーボードほか）を、今使っている値にそろえる。
# 作り直した Mac で一度走らせ、ログインし直す。Dock に並べるアプリは手で置く。
# 値を変えたら、システム設定で変えてから `defaults read <domain> <key>` で読み、ここを直す。
set -euo pipefail
[[ "$(uname -s)" == Darwin ]] || { echo "macOS 専用です" >&2; exit 1; }

# 外観
defaults write NSGlobalDomain AppleInterfaceStyle -string Dark
defaults write NSGlobalDomain AppleShowScrollBars -string WhenScrolling
defaults write com.apple.menuextra.clock ShowSeconds -bool true

# キーボード: キーのリピートを速く、文頭の自動の大文字をやめる
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# トラックパッド: タップでクリック、3 本指でドラッグ（3 本指のスワイプは 4 本指に回す）、軌跡の速さ
for domain in com.apple.AppleMultitouchTrackpad com.apple.driver.AppleBluetoothMultitouch.trackpad; do
  defaults write "$domain" Clicking -bool true
  defaults write "$domain" TrackpadThreeFingerDrag -bool true
  defaults write "$domain" TrackpadThreeFingerHorizSwipeGesture -int 0
  defaults write "$domain" TrackpadThreeFingerVertSwipeGesture -int 0
  defaults write "$domain" TrackpadFourFingerHorizSwipeGesture -int 2
  defaults write "$domain" TrackpadFourFingerVertSwipeGesture -int 2
done
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.trackpad.scaling -float 2

# Dock: 自動で隠す、最近のアプリを出さない、ホットコーナー（左上: ディスプレイをスリープ、右上: なし、右下: クイックメモ）
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock tilesize -int 60
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock wvous-tl-corner -int 10
defaults write com.apple.dock wvous-tl-modifier -int 0
defaults write com.apple.dock wvous-tr-corner -int 1
defaults write com.apple.dock wvous-tr-modifier -int 0
defaults write com.apple.dock wvous-br-corner -int 14
defaults write com.apple.dock wvous-br-modifier -int 0

# Finder: 拡張子を出す、リスト表示、フォルダを先に、新しいウインドウはホーム、検索は今のフォルダ
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder FXPreferredViewStyle -string Nlsv
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.finder NewWindowTarget -string PfHm
defaults write com.apple.finder FXDefaultSearchScope -string SCcf

# ネットワークのボリュームに .DS_Store を書かない。スクリーンショットに影を付けない
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.screencapture disable-shadow -bool true

killall Dock Finder SystemUIServer 2>/dev/null || true
echo "済みました。トラックパッドとキーボードの一部は、ログインし直すと効きます"
