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
   - 漲跌家數：MCP 的 `get_market_gain_loss_statistics` 資料停在 2026-06-05 沒更新，改以證交所網站端點為主（`date` 為目標日 YYYYMMDD）：
     ```
     curl -s "https://www.twse.com.tw/rwd/zh/afterTrading/MI_INDEX?date=<YYYYMMDD>&type=MS&response=json"
     ```
     `stat` 為 `OK` 才有效；在 `tables` 中找 `title` 為「漲跌證券數合計」的表，欄位為 類型｜整體市場｜股票，列為 上漲(漲停)、下跌(跌停)、持平、未成交、無比價，值如 `422(23)` 表示 422 家、其中漲停 23。frontmatter 的 `up_count`、`down_count` 用「股票」欄（整體市場含權證）。curl 失敗時才呼叫 MCP 工具，並檢查回傳日期（民國年，如 1150605）是否為目標日，不是就在區塊註明並讓 `up_count`、`down_count` 留空。
   - `get_top_20_volume_stocks` → 成交量前 20。**檢查回傳的「日期」**：這個工具資料更新很慢，盤後常常還是前一交易日。日期不是目標日時，改用證交所網站端點（`date` 為目標日 YYYYMMDD）：
     ```
     curl -s "https://www.twse.com.tw/rwd/zh/afterTrading/MI_INDEX20?date=<YYYYMMDD>&response=json"
     ```
     回傳 JSON 的 `stat` 為 `OK` 才有效；`data` 每列欄位依序為 排名、代號、名稱、成交股數、成交筆數、開、高、低、收、漲跌符號（HTML，`green` 為跌、`red` 為漲）、漲跌價差…；名稱可能帶 `*`，要去掉。兩個來源都拿不到目標日資料時，才在該區塊註明資料日期不是當日。
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
5. 內文、表格中的日期一律寫 `YYYY/MM/DD`（標題 `# YYYY/MM/DD 盤後日報`），frontmatter `date` 維持 `YYYY-MM-DD`。
6. 不修改「持股快報」（Dataview）與「今日心得」區塊。
7. 回報摘要與檔案路徑。若使用者持股有異常（跌幅 > 5%、被列注意股），在回報中提醒。
