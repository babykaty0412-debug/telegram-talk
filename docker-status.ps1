# docker-status.ps1
# 取代 Docker Desktop 儀表板的容器管理工具。
#
# 為什麼需要它：
#   Docker Desktop 的儀表板視窗只要開著，就會每 10 秒跑 3 次
#   `docker stats`，每次都閃一個黑底 console 視窗（實測 36 次/分鐘）。
#   Docker 沒有任何設定可以關掉這個輪詢 —— 唯一解是不開那個視窗。
#   本腳本提供儀表板該有的功能，且只在你執行時跑一次，不輪詢、不閃。
#
# 用法：
#   & E:\claude\docker-status.ps1                  總覽（狀態 / 埠 / 資源用量）
#   & E:\claude\docker-status.ps1 -Logs web        看 web 最近 30 行日誌
#   & E:\claude\docker-status.ps1 -Logs web -Tail 100
#   & E:\claude\docker-status.ps1 -Follow web      即時跟隨日誌（Ctrl+C 離開）
#   & E:\claude\docker-status.ps1 -Restart web     重啟單一容器
#   & E:\claude\docker-status.ps1 -RestartAll      整組重啟（docker compose restart）
#   & E:\claude\docker-status.ps1 -Web             測試網站是否真的回應

param(
    [string]$Logs,
    [string]$Follow,
    [string]$Restart,
    [switch]$RestartAll,
    [switch]$Web,
    [int]$Tail = 30
)

$docker  = "C:\Program Files\Docker\Docker\resources\bin\docker.exe"
$project = "E:\claude\projects\selfhost-lab\services\web"

if (-not (Test-Path $docker)) {
    Write-Host "找不到 docker.exe：$docker" -ForegroundColor Red
    exit 1
}

# 引擎沒開的話後面都不用做了
$null = & $docker info 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker 引擎沒有在執行。" -ForegroundColor Red
    Write-Host "從系統匣啟動 Docker Desktop 即可（啟動後把儀表板視窗關掉，避免閃爍）。"
    exit 1
}

# ── 單一動作模式 ──────────────────────────────────────────────
if ($Logs)    { & $docker logs $Logs --tail $Tail; exit $LASTEXITCODE }
if ($Follow)  { & $docker logs $Follow --tail $Tail -f; exit $LASTEXITCODE }
if ($Restart) {
    Write-Host "重啟 $Restart ..." -ForegroundColor Yellow
    & $docker restart $Restart
    Start-Sleep -Seconds 3
    & $docker ps --filter "name=$Restart" --format "  {{.Names}}  {{.Status}}"
    exit 0
}
if ($RestartAll) {
    Write-Host "整組重啟（$project）..." -ForegroundColor Yellow
    Push-Location $project
    & $docker compose restart
    Pop-Location
    Start-Sleep -Seconds 3
    & $docker ps --format "  {{.Names}}  {{.Status}}"
    exit 0
}

# ── 總覽 ─────────────────────────────────────────────────────
Write-Host ""
Write-Host "══ 容器狀態 ══════════════════════════════════" -ForegroundColor Cyan
$rows = & $docker ps -a --format "{{.Names}}|{{.Status}}|{{.Ports}}|{{.Image}}"
if (-not $rows) {
    Write-Host "  （沒有任何容器）" -ForegroundColor DarkGray
} else {
    foreach ($r in $rows) {
        $n, $s, $p, $img = $r -split '\|'
        # Paused / Exited 要醒目：暫停等於網站掛掉
        $color = if ($s -match 'Paused')      { 'Red' }
                 elseif ($s -match '^Up')     { 'Green' }
                 else                         { 'Yellow' }
        $mark  = if ($s -match 'Paused')      { '暫停中！' }
                 elseif ($s -match '^Up')     { 'OK' }
                 else                         { '未執行' }
        Write-Host ("  {0,-14} {1,-8} {2}" -f $n, $mark, $s) -ForegroundColor $color
        if ($p) { Write-Host ("  {0,-14} 埠  {1}" -f '', $p) -ForegroundColor DarkGray }
        Write-Host ("  {0,-14} 映像 {1}" -f '', $img) -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "══ 資源用量（單次取樣，不輪詢）══════════════" -ForegroundColor Cyan
$stats = & $docker stats --no-stream --format "{{.Name}}|{{.CPUPerc}}|{{.MemUsage}}" 2>$null
if ($stats) {
    foreach ($s in $stats) {
        $n, $cpu, $mem = $s -split '\|'
        Write-Host ("  {0,-14} CPU {1,-8} 記憶體 {2}" -f $n, $cpu, $mem)
    }
} else {
    Write-Host "  （沒有執行中的容器）" -ForegroundColor DarkGray
}

# 有暫停的容器就直接給指令，不用另外查
$paused = & $docker ps -a --filter "status=paused" --format "{{.Names}}"
if ($paused) {
    Write-Host ""
    Write-Host "  ⚠ 有容器被暫停，網站可能是斷的。恢復指令：" -ForegroundColor Red
    Write-Host "    docker unpause $($paused -join ' ')" -ForegroundColor Yellow
}

if ($Web) {
    Write-Host ""
    Write-Host "══ 網站回應測試 ══════════════════════════════" -ForegroundColor Cyan
    try {
        $r = Invoke-WebRequest -Uri "http://localhost:8080" -UseBasicParsing -TimeoutSec 8
        Write-Host "  localhost:8080 → HTTP $($r.StatusCode)" -ForegroundColor Green
    } catch {
        Write-Host "  localhost:8080 → 無回應（$($_.Exception.Message)）" -ForegroundColor Yellow
        Write-Host "  註：本機測試失敗不代表對外網站掛掉，用下一行確認實際流量" -ForegroundColor DarkGray
        Write-Host "      & E:\claude\docker-status.ps1 -Logs web" -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "常用：" -ForegroundColor DarkGray
Write-Host "  -Logs web        看日誌      -Follow web    即時跟隨" -ForegroundColor DarkGray
Write-Host "  -Restart web     重啟容器    -RestartAll    整組重啟" -ForegroundColor DarkGray
Write-Host "  -Web             測網站回應" -ForegroundColor DarkGray
Write-Host ""
