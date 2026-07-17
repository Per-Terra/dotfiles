#!/bin/bash
# ~/.claude/statusline.sh
# 公式ドキュメントの全例を統合した Claude Code ステータスライン
#
# 表示内容:
#   Line 1: [モデル名 effort:high]  📁 プロジェクト名  |  ⎇ ブランチ ●staged ~modified
#   Line 2: ▓▓▓▓░░░░░░ XX%  |  $0.0042  |  3m20s  |  +156 -23  |  rate:23%
#
# 依存: jq (sudo apt install jq)
# 配置: chmod +x ~/.claude/statusline.sh
# 設定: ~/.claude/settings.json に下記を追加
#   { "statusLine": { "type": "command", "command": "~/.claude/statusline.sh" } }

set -euo pipefail

# ---- JSON 読み込み ----
input=$(cat)

# ---- フィールド抽出（null 安全: // でフォールバック） ----
MODEL=$(    echo "$input" | jq -r '.model.display_name               // "unknown"')
DIR=$(      echo "$input" | jq -r '.workspace.current_dir            // ""')
REPO=$(     echo "$input" | jq -r '.workspace.repo.name              // ""')
PCT=$(      echo "$input" | jq -r '.context_window.used_percentage   // 0' | cut -d. -f1)
COST=$(     echo "$input" | jq -r '.cost.total_cost_usd              // 0')
MS=$(       echo "$input" | jq -r '.cost.total_duration_ms           // 0')
ADDED=$(    echo "$input" | jq -r '.cost.total_lines_added           // 0')
REMOVED=$(  echo "$input" | jq -r '.cost.total_lines_removed         // 0')
EFFORT=$(   echo "$input" | jq -r '.effort.level                     // ""')
RATE_5H=$(  echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty' 2>/dev/null || echo "")

# ---- Git 情報（コマンド経由） ----
BRANCH=$(   git -C "$DIR" branch --show-current     2>/dev/null || echo "")
STAGED=$(   git -C "$DIR" diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
MODIFIED=$( git -C "$DIR" diff --name-only          2>/dev/null | wc -l | tr -d ' ')

# ---- 表示名（repo名 → ディレクトリ名 の優先順） ----
PROJECT="${REPO:-${DIR##*/}}"
PROJECT="${PROJECT:-(unknown)}"

# ---- 経過時間フォーマット ----
SECS=$((MS / 1000))
if   [ "$SECS" -lt 60 ];   then DURATION="${SECS}s"
elif [ "$SECS" -lt 3600 ]; then DURATION="$((SECS / 60))m$((SECS % 60))s"
else                             DURATION="$((SECS / 3600))h$((SECS % 3600 / 60))m"
fi

# ---- コンテキストバー（10ブロック） ----
FILLED=$((PCT / 10))
BAR=""
for i in $(seq 1 10); do
  [ "$i" -le "$FILLED" ] && BAR+="▓" || BAR+="░"
done

# ---- ANSI エスケープ ----
RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"
CYAN="\033[36m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
MAGENTA="\033[35m"
BLUE="\033[34m"

# コンテキスト使用率に応じてバーの色を変える
if   [ "$PCT" -ge 80 ]; then CTX_COLOR="$RED"
elif [ "$PCT" -ge 50 ]; then CTX_COLOR="$YELLOW"
else                         CTX_COLOR="$GREEN"
fi

# ---- Git パートの組み立て ----
if [ -n "$BRANCH" ]; then
  GIT_PART="${CYAN}⎇ ${BRANCH}${RESET}"
  [ "$STAGED"   -gt 0 ] && GIT_PART+=" ${GREEN}●${STAGED}${RESET}"
  [ "$MODIFIED" -gt 0 ] && GIT_PART+=" ${YELLOW}~${MODIFIED}${RESET}"
else
  GIT_PART="${DIM}(no git)${RESET}"
fi

# ---- effort パートの組み立て（フィールドが存在する場合のみ表示） ----
# effort はモデルが対応している場合のみ存在するフィールド
EFFORT_PART=""
if [ -n "$EFFORT" ]; then
  case "$EFFORT" in
    low)   EFFORT_PART=" ${DIM}effort:low${RESET}" ;;
    medium) EFFORT_PART=" ${BLUE}effort:med${RESET}" ;;
    high)  EFFORT_PART=" ${YELLOW}effort:high${RESET}" ;;
    xhigh) EFFORT_PART=" ${MAGENTA}effort:xhigh${RESET}" ;;
    max)   EFFORT_PART=" ${RED}effort:max${RESET}" ;;
  esac
fi

# ---- rate limit パートの組み立て（Pro/Max のみ存在するフィールド） ----
RATE_PART=""
if [ -n "$RATE_5H" ]; then
  RATE_INT=$(echo "$RATE_5H" | cut -d. -f1)
  if   [ "$RATE_INT" -ge 80 ]; then RATE_COLOR="$RED"
  elif [ "$RATE_INT" -ge 50 ]; then RATE_COLOR="$YELLOW"
  else                               RATE_COLOR="$GREEN"
  fi
  RATE_PART="  ${DIM}|${RESET}  ${RATE_COLOR}rate:${RATE_INT}%${RESET}"
fi

# ---- コスト整形 ----
COST_FMT=$(printf "\$%.4f" "$COST")

# ================================================================
# 出力（2行）
# ================================================================

# 1行目: [モデル名 effort]  📁 プロジェクト  |  ⎇ ブランチ
printf "${BOLD}${MAGENTA}[%s${RESET}%b${BOLD}${MAGENTA}]${RESET}  ${BOLD}📁 %s${RESET}  ${DIM}|${RESET}  %b\n" \
  "$MODEL" "$EFFORT_PART" "$PROJECT" "$GIT_PART"

# 2行目: コンテキストバー | コスト | 経過時間 | 変更行数 | レートリミット
printf "${CTX_COLOR}%s${RESET} %s%%  ${DIM}|${RESET}  ${YELLOW}%s${RESET}  ${DIM}|${RESET}  ${DIM}%s${RESET}  ${DIM}|${RESET}  ${GREEN}+%s${RESET} ${RED}-%s${RESET}%b\n" \
  "$BAR" "$PCT" "$COST_FMT" "$DURATION" "$ADDED" "$REMOVED" "$RATE_PART"
