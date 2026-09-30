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

  claude -p "今天是 $(date +%F)。依序執行：
1. /daily-report（若今天非交易日，直接結束，不要產生任何檔案）
2. /update-stock 持有
3. /update-stock 觀察
遵守 CLAUDE.md 規則。最後輸出一段簡短摘要。" \
    --allowedTools "mcp__twstockmcpserver" "Read" "Write" "Edit" "Glob" "Grep" "Skill" "Bash(ls:*)" "Bash(mkdir:*)" "Bash(date:*)"

  echo "=== $(date '+%F %T') 結束（exit $?）==="
} >> "$LOG" 2>&1

# 只保留 30 天的 log
find "$VAULT/logs" -name '*.log' -mtime +30 -delete
