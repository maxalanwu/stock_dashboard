---
name: update-macro
description: 用 twstockmcpserver 更新國發會景氣燈號，寫入 Obsidian vault 的 40_Macro/景氣燈號.md（首頁會顯示）。當使用者說「景氣燈號」「更新總經」「/update-macro」時使用。
---

# 更新景氣燈號

國發會每月下旬（約 27 日）公布前一個月的燈號，資料月份沒變就不必改寫。

## 步驟

1. 讀取 `40_Macro/景氣燈號.md` 的 frontmatter `data_month`。
2. 呼叫 `get_business_cycle_indicators(months=24)`（table 預設 `signal`）。取最新一筆**有景氣對策信號分數**的月份為資料月份。
   - 資料月份與 `data_month` 相同 → 只回報「景氣燈號無新資料（最新 YYYY/MM）」，**不要修改檔案**。
3. 有新資料時，再平行呼叫 `get_business_cycle_indicators`：`months=2, table="signal_components"`，以及 `months=1` 的 `table="leading"`、`"coincident"`、`"lagging"`。
4. 更新 frontmatter（純數字，指數取「不含趨勢指數」四捨五入到小數 2 位）：
   `data_month`（字串 `"YYYY/MM"`）、`signal`（紅／黃紅／綠／黃藍／藍）、`signal_score`、`signal_score_prev`（前一月分數）、`leading_index`、`coincident_index`、`lagging_index`、`updated`（今天 YYYY-MM-DD）。
5. 只改寫 AUTO 區塊，格式：

   ```
   > 🤖 摘要（1~3 行：燈號、分數與前月比較、連續幾個月同燈號、領先／同時指標走向）

   ## 近 24 個月燈號          （```chart line，景氣對策信號分數，labels 由舊到新，格式 YYYY/MM）
   ## 領先／同時指標（不含趨勢）（```chart line，兩條 series）
   ## 近 12 個月明細          （表格由新到舊：月份｜燈號｜分數｜領先｜同時｜落後）
   ## 燈號構成項目（YYYY/MM） （表格：項目｜類別｜說明｜最新月｜前一月）
   ## 三類指標構成（YYYY/MM） （領先／同時／落後各一張表：項目｜說明｜最新月）
   燈號區間說明一行
   ```

   燈號 emoji：🔴 紅、🟠 黃紅、🟢 綠、🟡 黃藍、🔵 藍。chart 區塊沿用 `width: 100%`、`legendPosition: top`、`textColor: "#ffffff"`。

   「近 24 個月燈號」圖要畫出燈號區間底色，**沿用現有檔案的結構，只替換 labels、分數 data、點顏色陣列，以及各區間 series 的 data 長度**：
   - 第 1 個 series 為分數：`borderColor: "#ffffff"`、`pointRadius: 5`、`order: 0`，`pointBackgroundColor`／`pointBorderColor` 為與 data 等長的陣列，依該月燈號上色。
   - 之後依序 5 個區間 series（常數線，長度與 labels 相同），`borderWidth: 0`、`pointRadius: 0`、`pointHoverRadius: 0`、`pointHitRadius: 0`、`order: 1`，背景色為燈號色加 `33` 透明度：
     | title | data 常數 | fill | 顏色 |
     |---|---|---|---|
     | 藍燈 9–16 | 16.5 | origin | #1e88e5 |
     | 黃藍燈 17–22 | 22.5 | "-1" | #fdd835 |
     | 綠燈 23–31 | 31.5 | "-1" | #43a047 |
     | 黃紅燈 32–37 | 37.5 | "-1" | #fb8c00 |
     | 紅燈 38–45 | 45 | "-1" | #e53935 |
   - 圖表層級加 `yMin: 9`、`yMax: 45`，不要 `beginAtZero`。
   兩個構成項目區塊的「類別」「說明」欄與段落文字**沿用現有檔案，不要改寫**，只更新月份與數值（未公布寫「尚未公布」，數字加千分位）。若 MCP 回傳的項目與現有表格不同（國發會修訂指標），依新項目調整並在回報中提醒。
   內文與表格的月份一律寫 `YYYY/MM`、日期寫 `YYYY/MM/DD`。
6. 摘要客觀陳述數據，不做景氣或買賣判斷。回報資料月份、燈號與分數。
