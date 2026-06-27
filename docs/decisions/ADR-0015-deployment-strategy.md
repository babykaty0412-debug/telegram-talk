---
doc_type: adr
doc_id: ADR-0015
title: Deployment Strategy
status: accepted
version: "1.0"
date: 2026-06-27
supersedes: []
related: [ADR-0002, ADR-0011, ADR-0013]
tags: [deployment, docker, kubernetes, cloud, infra]
---

# ADR-0015: Deployment Strategy

## 狀態

`Accepted`（自 2026-06-27）

## 背景（Context）

PAOS 必須在不同的生命週期階段以不同的方式部署：
- V1：個人開發環境（Windows），需要快速啟動，允許手動操作
- V2：持續運行的服務（Linux 主機或容器），需要 24/7 可靠性
- V3：可擴展的雲端架構，可能需要水平擴展

ADR-0002 已定義平台策略（Architecture 與 OS 無關），本 ADR 定義具體的**部署形態**——如何打包、如何啟動、如何監控、如何升級。

---

## 三個部署目標

### 目標 D1：Development（開發 / 個人使用）

**適用場景**：V1，Windows 開發環境

**部署形態**：
```
直接執行：bun run start
守護進程：PowerShell watchdog（telegram-watchdog.ps1）
資料：本地 SQLite（data/paos.db）
設定：.env 檔案
```

**特性**：
- 啟動快、可隨時中斷
- Windows 工作排程器管理 watchdog
- 不需要 Docker 或任何額外基礎設施

**限制**：依賴 Windows 常駐、機器關機服務就停止。

---

### 目標 D2：Server（伺服器 / 24/7 服務）

**適用場景**：V2，Linux VPS 或本地 Linux 機器

**部署形態 D2a（systemd service）**：
```
systemd unit file → paos.service
資料：/var/lib/paos/paos.db
設定：環境變數（/etc/paos/env）
日誌：journald
```

**部署形態 D2b（Docker）**：
```yaml
# docker-compose.yml
services:
  paos:
    image: paos:latest
    environment:
      - PAOS_ENV=production
      - PAOS_DB_PATH=/data/paos.db
    volumes:
      - paos-data:/data
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
```

**選擇建議**：
- 有 Docker 經驗 → D2b（更易遷移）
- 熟悉 Linux 系統管理 → D2a（資源佔用更低）

---

### 目標 D3：Cloud-native（雲端 / 可擴展）

**適用場景**：V3，SaaS 或多人版本

**可能的部署平台**（V3 時再選擇，不現在決定）：
- **Fly.io / Railway**：簡單的 PaaS，從 Docker 一鍵部署
- **Cloud Run（GCP）**：Serverless 容器，按需計費
- **Kubernetes**：完整的容器編排，適合高流量

**現在需要做的**：確保 V1 的架構決策不阻礙 V3 的任何選項。

---

## 跨版本共同原則（Container-ready 設計）

即使 V1 不使用 Docker，所有設計決策必須確保「隨時可以容器化」。

### 原則 1：12-Factor App

| Factor | PAOS 的實踐 |
|---|---|
| Config | 所有設定透過環境變數（不硬編碼） |
| Backing Services | SQLite 路徑、AI API Endpoint 透過 `PAOS_DB_PATH`、`PAOS_AI_ENDPOINT` |
| Port Binding | API Server 監聽 `PORT` 環境變數 |
| Processes | 進程是無狀態的，狀態在 SQLite |
| Logs | 輸出到 stdout/stderr（不寫入本地日誌文件） |
| Admin Processes | 資料庫遷移等維護命令作為一次性命令執行 |

### 原則 2：Health Check Endpoint

**V1 起就必須實作**，即使在開發模式下也要有：

```
GET /health
Response: { status: 'ok', uptime: 3600, db: 'connected' }
```

### 原則 3：Graceful Shutdown

進程收到 `SIGTERM` 時，必須：
1. 停止接受新的任務
2. 等待正在執行的 Worker 完成（最多 30 秒）
3. 將未完成的任務狀態寫入 Task Queue（設為 `interrupted`）
4. 關閉 SQLite 連線
5. 退出進程

**理由**：Docker stop、systemd stop、Kubernetes pod 終止都會發送 SIGTERM。

### 原則 4：路徑與資料的可設定性

```
# 所有路徑必須可透過環境變數覆蓋
PAOS_ENV=development | production | test
PAOS_DB_PATH=/data/paos.db
PAOS_LOG_LEVEL=info | debug | error
PAOS_PORT=3000
```

---

## 環境變數規範

### 必填（所有環境）

| 變數 | 說明 | 範例 |
|---|---|---|
| `PAOS_ENV` | 執行環境 | `development` / `production` |
| `PAOS_DB_PATH` | SQLite 資料庫路徑 | `/data/paos.db` |

### 選填（依功能啟用）

| 變數 | 說明 |
|---|---|
| `PAOS_PORT` | API Server port（預設 3000） |
| `PAOS_LOG_LEVEL` | 日誌等級（預設 `info`） |
| `ANTHROPIC_API_KEY` | Claude API Key |
| `OPENAI_API_KEY` | OpenAI API Key |
| `TELEGRAM_BOT_TOKEN` | Telegram Bot Token |

**安全規則**：
- 所有含 `KEY`、`TOKEN`、`SECRET` 的變數不得出現在日誌或程式碼中
- `.env` 檔案永遠列在 `.gitignore` 中

---

## 升級策略

| 部署目標 | 升級方式 |
|---|---|
| D1（Development） | `git pull && bun install && bun run start`，watchdog 自動重啟 |
| D2a（systemd） | `systemctl stop paos && git pull && bun install && systemctl start paos` |
| D2b（Docker） | `docker pull paos:latest && docker compose up -d` |
| D3（Cloud） | CI/CD Pipeline 自動部署 |

**資料庫遷移**：升級前先備份 SQLite，遷移腳本放在 `tools/migrate/`

---

## 決策（Decision）

**PAOS 採用三個部署目標（D1/D2/D3），架構從 V1 起就遵循 12-Factor App 原則、實作 Health Check 和 Graceful Shutdown，確保任何時候都可以容器化。**

---

## 後果（Consequences）

### 正面影響
- V1 在 Windows 開發，V2 遷移到 Linux/Docker 不需要修改程式碼
- Health Check 讓監控系統（watchdog、Docker、Kubernetes）可以自動管理進程

### 負面影響（需接受的取捨）
- Graceful Shutdown 邏輯需要額外實作（約 50–100 行程式碼）
- 12-Factor App 要求所有設定透過環境變數——增加初次設定的複雜度

---

## 實施原則

1. V1 啟動腳本（`.bat`/`.ps1`）只負責設定環境變數和呼叫 `bun start`，不包含業務邏輯
2. `Dockerfile` 從 V1 就建立（即使不立即使用），確保容器化沒有遺漏
3. 資料庫遷移必須是冪等的（跑兩次結果相同）
4. `PAOS_ENV=test` 下所有 AI API 呼叫使用 Mock，不消耗真實 API quota

---

## 開放問題

| # | 問題 | 狀態 |
|---|---|---|
| 1 | V2 選擇 systemd 還是 Docker？ | Open（取決於伺服器環境） |
| 2 | V3 選擇哪個雲端平台？ | Open（V3 再決定） |
| 3 | SQLite 是否需要定期備份腳本？備份頻率？ | Open（建議：每日備份到另一個位置） |

---

## Changelog

| 版本 | 日期 | 說明 |
|---|---|---|
| 1.0 | 2026-06-27 | 初版，定義三個部署目標與跨版本共同原則 |
