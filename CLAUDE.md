# 股票分析 Obsidian Vault

資料來源：本機 docker 的 `twstockmcpserver`（台股 MCP）。

## 結構
- `00_Dashboard/` Dataview 總覽
- `10_Stocks/` 個股筆記，檔名 `<代號> <名稱>.md`
- `20_Daily/` 盤後日報，檔名 `YYYY-MM-DD.md`
- `30_Industry/` 產業頁（frontmatter `industry` 需與個股的 `industry` 一致）
- `40_Macro/` 總經（景氣燈號、PMI、匯率）
- `50_Journal/` 交易紀錄
- `90_Templates/` Templater 模板
- `_raw/` MCP 原始資料快照

## 規則
- 自動產生的內容只能寫在 `<!-- AUTO:START -->` 與 `<!-- AUTO:END -->` 之間，區塊外是使用者手寫內容，不可修改。
- frontmatter 數值寫純數字（不含 % 或千分位），日期用 YYYY-MM-DD。
- 圖表使用 Obsidian Charts 外掛的 ```chart 區塊，labels 由舊到新。
- `status`、`entry_price`、`target_price`、`stop_loss` 由使用者維護，自動更新時不要覆蓋。
- 摘要客觀陳述數據，不提供買賣建議。

## 指令
- `/update-stock <代號...>`：更新或新建個股（也可用 `持有`、`觀察` 批次更新）
- `/daily-report [日期]`：產生盤後日報
