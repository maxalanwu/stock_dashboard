#!/bin/zsh
# 由 launchd 於每個工作日 16:00 執行：產生盤後日報並更新持有/觀察個股
export PATH="/Users/jk/.local/bin:/Users/jk/.docker/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
VAULT="/Users/jk/project/stock_analysis"
LOG="$VAULT/logs/$(date +%Y-%m-%d).log"
cd "$VAULT" || exit 1

{
  echo "=== $(date '+%F %T') 開始 ==="

  # 確認 Docker 可用（最多等 2 分鐘）
  for i in {1..24}; do docker info >/dev/null 2>&1 && break; sleep 5; done
  docker info >/dev/null 2>&1 || { echo "Docker 未啟動，中止"; exit 1; }

  # 景氣燈號：國發會約每月 27 日公布上個月資料。27 日起應有上個月、之前應有上上個月，
  # 筆記的 data_month 比應有月份舊才更新（公布延到下個月初也會補抓）
  y=$(date +%Y); m=$(date +%m); d=$(date +%d)
  (( 10#$d >= 27 )) && back=1 || back=2
  n=$(( 10#$y * 12 + 10#$m - 1 - back ))
  expected=$(printf '%04d/%02d' $(( n / 12 )) $(( n % 12 + 1 )))
  current=$(sed -n 's|^data_month: *"\{0,1\}\([0-9/]*\)"\{0,1\}.*|\1|p' "$VAULT/40_Macro/景氣燈號.md")
  if [[ "$current" < "$expected" ]]; then
    echo "景氣燈號：現有 $current，應有 $expected，本次更新"
    macro_step="
4. /update-macro（無論是否交易日都執行）"
  else
    echo "景氣燈號：已是 $current，略過"
    macro_step=""
  fi

  claude -p "今天是 $(date +%F)。依序執行：
1. /daily-report（若今天非交易日，跳過步驟 1~3，不要產生日報或更新個股）
2. /update-stock 持有
3. /update-stock 觀察$macro_step
遵守 CLAUDE.md 規則。最後輸出一段簡短摘要。" \
    --allowedTools "mcp__twstockmcpserver" "Read" "Write" "Edit" "Glob" "Grep" "Skill" "Bash(ls:*)" "Bash(mkdir:*)" "Bash(date:*)" "Bash(curl:*)"

  echo "=== $(date '+%F %T') 結束（exit $?）==="
} >> "$LOG" 2>&1

# 只保留 30 天的 log
find "$VAULT/logs" -name '*.log' -mtime +30 -delete
