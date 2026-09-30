---
name: update-stock
description: 用 twstockmcpserver 抓取個股資料並更新 Obsidian vault 中 10_Stocks/ 的個股筆記。當使用者說「更新 2330」「/update-stock 2330 2317」「幫我建一檔股票」「更新持股」時使用。
---

# 更新個股筆記

參數：一或多個股票代號（空白分隔）。若參數為 `持有` 或 `觀察`，則掃描 `10_Stocks/` 中 frontmatter `status` 相符的所有檔案並逐一更新。

## 步驟

1. **找檔案**：在 `10_Stocks/` 找 `<代號> *.md`。若不存在，依 `90_Templates/個股模板.md` 的 frontmatter 與區塊結構新建 `<代號> <名稱>.md`（Templater 語法要替換成實際值，`status: 觀察`）。
2. **判斷市場**：`get_company_profile` 有資料 → 上市；否則視為上櫃，改用 OTC 系列工具（`get_otc_valuation`、`get_otc_institutional`、`get_otc_margin_balance`、`get_otc_foreign_holdings`）。
3. **平行呼叫 MCP**（上市為例）：
   - `get_company_profile(code)` → 產業、董事長、資本額、主要業務
   - `get_realtime_quote([code])` → 收盤價、漲跌幅
   - `get_stock_valuation_ratios(stock_no=code)` → PE / PB / 殖利率
   - `get_company_monthly_revenue(code, start_month=12個月前, end_month=最新月)` → 近 12 月營收
   - `get_company_income_statement(code)` → 最新一季損益
   - 近 8 季趨勢：另外呼叫 `get_company_income_statement(code, year, season)` 取得更早的季度。每次回傳都含「當季」與「去年同季」，所以只要查最近 4 季，就能湊出 8 季。**Q4 只有全年數字**，單季 Q4 要用「全年 − 前三季累計（Q3 報表的累計欄）」自己算，所以 Q3 和 Q4 都要查。
   - EPS TTM = 近四季單季 EPS 加總（不要用 股價 ÷ PE 推算）
   - `get_company_dividend(code)` → 近兩年股利
   - `get_technical_indicators(code, days=10)` → 均線、KD、RSI、MACD
   - `get_foreign_holdings(stock_no=code)` → 外資持股比
   - `get_margin_balance(stock_no=code)` → 融資融券
   - `get_twse_institutional_investors_by_stock(code, date)` → 最近 5 個交易日三大法人（逐日呼叫，非交易日跳過）
   - `get_company_major_news(code, limit=5)` → 近期重大訊息
   某工具失敗時在該區塊寫「⚠️ 資料取得失敗：<原因>」，不要中斷整體流程。
4. **改寫 AUTO 區塊**：只替換 `<!-- AUTO:START -->` 與 `<!-- AUTO:END -->` 之間的內容，**絕不修改區塊外的手寫內容**（我的論點、追蹤日誌）。區塊格式：

   ```
   > 🤖 AI 摘要（3~5 行：營收趨勢、獲利、籌碼、技術面重點，客觀陳述，不給買賣建議）
   > 資料更新：YYYY-MM-DD HH:mm

   ## 基本資料
   ## 估值         （表格：收盤、PE、PB、殖利率、EPS TTM）
   ## 月營收       （表格：月份｜營收(億)｜MoM｜YoY｜累計YoY，由新到舊；營收單位換算成億元）
                   + 圖表：月營收長條圖、YoY／累計 YoY 折線圖
   ## 獲利         （最新一季：營收、毛利率、營益率、淨利率、EPS 與去年同季比較）
     ### 近 8 季趨勢（表格：季度｜營收(億)｜毛利率｜營益率｜淨利率｜EPS，由新到舊，註明 Q4 為推算）
                   + 圖表：EPS 長條圖、三率折線圖
   ## 股利         （表格：所屬期間｜現金股利｜股票股利）
   ## 籌碼         （外資持股比、近 5 日三大法人買賣超表格(張)、融資融券餘額）
                   + 圖表：三大法人分組長條圖
   ```

   **圖表格式**：使用 Obsidian Charts 外掛的 ```` ```chart ```` 區塊（YAML）。規則如下：
   - 圖表的 labels 一律由舊到新（左舊右新），和表格方向相反。
   - 數值寫純數字。
   - 每張圖都加 `width: 100%`、`legendPosition: top`；長條圖加 `beginAtZero: true`，折線圖加 `tension: 0.2`。
   - 月份標籤用 `YY-MM`，季度標籤用 `115Q2`，日期標籤用 `MM-DD`。

   範例（三大法人）：
   ```chart
   type: bar
   labels: [09-22, 09-23, 09-24, 09-29, 09-30]
   series:
     - title: 外資(張)
       data: [-4330, 7123, -4668, -3736, 703]
     - title: 投信(張)
       data: [-406, -1143, -1288, 629, 762]
     - title: 自營商(張)
       data: [467, 324, 243, 117, 400]
   width: 100%
   legendPosition: top
   ```

   其餘區塊格式：
   ```
   ## 技術面       （MA5/20/60 位置、KD、RSI、MACD，一句話描述趨勢）
   ## 重大訊息     （最近 5 則：日期 + 主旨）
   ```

5. **更新 frontmatter**：`name, market, industry, price, change_pct, pe, pb, dividend_yield, eps_ttm, revenue_yoy`（最新月）, `revenue_ytd_yoy, foreign_ratio, foreign_net_5d, trust_net_5d`（單位：張）, `k, d, rsi, updated`（YYYY-MM-DD）。數值一律寫純數字（不含 %、逗號），Dataview 才能排序比較。**不要動** `status, entry_price, target_price, stop_loss, tags` 的既有值。
6. **原始資料**（選用）：若使用者要求保留原始資料，存到 `_raw/<代號>/<YYYY-MM-DD>.json`。
7. 完成後回報：更新了哪些股票、每檔 1 行重點、有哪些工具失敗。
