---
name: daily-report
description: 用 twstockmcpserver 產生台股盤後日報，寫入 Obsidian vault 的 20_Daily/YYYY-MM-DD.md。當使用者說「日報」「今天盤勢」「/daily-report」時使用。可選參數為日期 YYYY-MM-DD。
---

# 盤後日報

參數：日期（選填，預設今天；若非交易日則用最近一個交易日，可用 `get_market_holiday_schedule` 判斷）。

## 步驟

1. 目標檔：`20_Daily/<YYYY-MM-DD>.md`。不存在就依 `90_Templates/日報模板.md` 建立（Templater 語法換成實際值）。
2. 平行呼叫 MCP：
   - `get_taiex_index_history` → 加權指數收盤、漲跌
   - `get_otc_index` → 櫃買指數
   - `get_twse_institutional_investors_summary` → 三大法人買賣超金額
   - `get_market_gain_loss_statistics` → 漲跌家數
   - `get_top_20_volume_stocks` → 成交量前 20
   - `get_today_notice_stocks`、`get_market_disposal_stocks` → 注意 / 處置股
   - `get_twse_news` → 證交所新聞
   - 讀取 `10_Stocks/` 中 `status: 持有` 的代號，用 `get_realtime_quote` 一次查詢
3. 只改寫 AUTO 區塊，格式：

   ```
   > 🤖 今日盤勢摘要（3~5 行）

   ## 大盤         （加權、櫃買：收盤、漲跌點、漲跌%、成交金額）
   ## 三大法人     （外資／投信／自營商 買賣超，單位億元）
   ## 漲跌家數
   ## 成交量前 20  （表格；持股或觀察清單中的股票以 **粗體** 並附 [[連結]]）
   ## 注意 / 處置股（若與 10_Stocks 有交集要特別標示 ⚠️）
   ## 市場新聞     （5 則以內）
   ```

4. 更新 frontmatter：`taiex, taiex_change_pct, otc, otc_change_pct, foreign_net_bn, trust_net_bn, dealer_net_bn, up_count, down_count`（純數字）。
5. 不修改「持股快報」（Dataview）與「今日心得」區塊。
6. 回報摘要與檔案路徑。若使用者持股有異常（跌幅 > 5%、被列注意股），在回報中提醒。
