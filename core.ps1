<### core 管理工具
1.把相关 内核 及 配置文件 放在统一子目录；
2.将此脚本 core.ps1 放于根目录；
3.终端执行命令： notepad $PROFILE  打开 PowerShell 配置文件，添加以下行以启用 core 快捷命令：
    
    function core { & "D:\app\core\core.ps1" @args }

保存后，重启 PowerShell 以加载配置。

建议目录结构：
D:\app\core\
        ├── core.ps1
        |
        ├── singbox\
        |   ├── config.yaml
        |   ├── mihomo.exe
        |
        └── mihomo\
            ├── config.yaml
            ├── mihomo.exe

## 注意‼️‼️‼️：路径请按实际情况修改
##>

param(
    [string]$cmd,
    [string]$arg
)

# 根目录 (自行修改实际内核文件夹路径)
$root = "D:\app\core"
$coreFile = "$root\.core"

# 默认内核初始化 (使用兼容的读取方式)
if (!(Test-Path $coreFile)) {
    "mihomo" | Out-File $coreFile -Encoding ascii
}

# 兼容 PowerShell 5.1 的读取方式
$currentCore = (Get-Content $coreFile | Out-String).Trim()

# ------------------------
# 核心识别函数
# ------------------------

function Get-FolderStatus {
    param($dirName)
    $dirPath = Join-Path $root $dirName
    if (!(Test-Path $dirPath)) { return $null }

    # 1. 寻找内核 (mihomo*.exe 或 sing-box*.exe)
    $exe = Get-ChildItem $dirPath -Filter "*.exe" | Where-Object { 
        $_.Name -match "^mihomo.*\.exe$" -or $_.Name -match "^sing-box.*\.exe$" 
    } | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    
    # 2. 寻找配置文件 (找最大的 .yaml 或 .json)
    $cfg = Get-ChildItem $dirPath | Where-Object { 
        $_.Extension -match "\.(yaml|yml|json)$" 
    } | Sort-Object Length -Descending | Select-Object -First 1
    
    return @{
        name     = $dirName
        workdir  = $dirPath
        exe      = $exe
        config   = $cfg
        isValid  = ($exe -ne $null -and $cfg -ne $null)
        type     = if ($cfg -and $cfg.Extension -match "yaml|yml") { "mihomo" } else { "sing-box" }
    }
}

# ------------------------
# 加载当前环境变量
# ------------------------

$currentInfo = Get-FolderStatus $currentCore
if ($currentInfo -and $currentInfo.isValid) {
    $workdir     = $currentInfo.workdir
    $exePath     = $currentInfo.exe.FullName
    $processName = $currentInfo.exe.BaseName
    $config      = $currentInfo.config.FullName
    $type        = $currentInfo.type
} else {
    $processName = ""
    $type = "未知"
}

# ------------------------
# 工具函数
# ------------------------

function Get-ControllerPort {
    if (!$config -or !(Test-Path $config)) { return 9090 }
    $content = Get-Content $config | Out-String
    if ($content -match "external-controller\s*:\s*['""]?([0-9\.]+):(\d+)['""]?") { return $matches[2] }
    if ($content -match """external_controller""\s*:\s*""([0-9\.]+):(\d+)""") { return $matches[2] }
    return 9090
}

function Get-UIPath {
    if (!$config -or !(Test-Path $config)) { return "ui" }
    $content = Get-Content $config | Out-String
    if ($content -match "external[-_]ui\s*[:]\s*['""]?([^'""\s,]+)['""]?") { return $matches[1].Trim() }
    return "ui"
}

# ------------------------
# 权限检查工具函数
# ------------------------
function Test-Admin {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Assert-Admin {
    if (-not (Test-Admin)) {
        Write-Host "------------------------------------------------" -ForegroundColor Red
        Write-Host " ⚠️ 权限不足：此操作需要【管理员权限】" -ForegroundColor Red
        Write-Host " 请右键点击 PowerShell 选择 '以管理员身份运行'" -ForegroundColor Yellow
        Write-Host " 或者组合键：win + R 按 A" -ForegroundColor Gray
        Write-Host "------------------------------------------------" -ForegroundColor Red
        return $false
    }
    return $true
}

# ------------------------
# 核心控制命令
# ------------------------

function Start-Core {
    if (-not (Assert-Admin)) { return } # 拦截非管理员请求

    if (!$currentInfo -or !$currentInfo.isValid) {
        Write-Host "错误: $currentCore 目录配置不完整，无法启动。" -ForegroundColor Red
        return
    }
    if (Get-Process -Name $processName -ErrorAction SilentlyContinue) {
        Write-Host "[$currentCore] 已在运行" -ForegroundColor Yellow
        return
    }
    
    $runArgs = if ($type -eq "mihomo") { "-f `"$config`"" } else { "run -c `"$config`"" }
    
    try {
        Start-Process $exePath -ArgumentList $runArgs -WorkingDirectory $workdir -WindowStyle Hidden -ErrorAction Stop
        Write-Host "[$currentCore] 已成功启动" -ForegroundColor Green
    } catch {
        Write-Host "启动失败: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Stop-Core {
    if (-not (Assert-Admin)) { return $false } # 拦截非管理员请求

    $p = Get-Process -Name $processName -ErrorAction SilentlyContinue
    if (-not $p) {
        Write-Host "[$currentCore] 未运行" -ForegroundColor Gray
        return $true
    }

    Write-Host "尝试停止 [$processName] (PID: $($p.Id))..." -ForegroundColor Cyan

    try {
        # 先尝试正常关闭
        $p.CloseMainWindow() | Out-Null
        $p | Wait-Process -Timeout 2 -ErrorAction SilentlyContinue

        if (!$p.HasExited) {
            # 再尝试强制关闭
            Write-Host "正在强制结束进程..." -ForegroundColor DarkYellow
            Stop-Process -Id $p.Id -Force -ErrorAction Stop
        }
        
        Write-Host "✅ [$currentCore] 已停止" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "❌ 停止失败：$($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Restart-Core {
    if (Stop-Core) {
        Start-Sleep -Milliseconds 500
        Start-Core
    }
}

function Status-Core {
    Write-Host ""
    Write-Host " Core 状态" -ForegroundColor Cyan
    Write-Host "----------------------------------------" -ForegroundColor DarkGray
    Write-Host " 当前内核: " -NoNewline
    Write-Host "$currentCore" -ForegroundColor Green
    $p = Get-Process -Name $processName -ErrorAction SilentlyContinue
    if (!$p) {
        Write-Host " 运行状态: " -NoNewline
        Write-Host "Stopped" -ForegroundColor Red
    } else {
        Write-Host " 运行状态: " -NoNewline
        Write-Host "Running" -ForegroundColor Green
        Write-Host " PID : $($p.Id)"
        Write-Host " 内存: $("{0:N2}" -f ($p.WorkingSet64 / 1MB)) MB"
        if ($config) { Write-Host " 配置文件: $(Split-Path $config -Leaf)" }
    }
    Write-Host " 控制端口: $(Get-ControllerPort)"
    Write-Host "----------------------------------------" -ForegroundColor DarkGray
        Write-Host ""
        return
}

function Watch-Core {
    if (!$processName) { 
        Write-Host " 错误: 当前未选定内核或内核未运行" -ForegroundColor Red
        return 
    }

    # 1. 预留 8 行空间并锁定起始位置，防止触底位移
    Write-Host "`n`n`n`n`n`n`n`n"
    $originY = [Console]::CursorTop - 8
    
    # 2. 隐藏光标以减少微小闪烁
    $oldCursorSize = $Host.UI.RawUI.CursorSize
    try { $Host.UI.RawUI.CursorSize = 0 } catch {}

    try {
        while ($true) {
            # 3. 每一帧都回到锁定的原点
            [Console]::SetCursorPosition(0, $originY)

            # 4. 关键：所有输出必须 PadRight(60) 补齐，确保完全覆盖上一帧
            Write-Host " Core 实时状态 " -ForegroundColor Cyan -NoNewline
            Write-Host "    (按 Ctrl + C 退出)".PadRight(60) -ForegroundColor Magenta
            Write-Host "----------------------------------------".PadRight(60) -ForegroundColor DarkGray

            $p = Get-Process -Name $processName -ErrorAction SilentlyContinue
            if (!$p) {
                Write-Host " 当前内核: " -NoNewline
                Write-Host "$processName.exe".PadRight(60) -ForegroundColor Gray
                Write-Host " 运行状态: " -NoNewline
                Write-Host "Stopped".PadRight(60) -ForegroundColor Red

                Write-Host "".PadRight(60)
                Write-Host "".PadRight(60)
                Write-Host "".PadRight(60)
            } else {
                Write-Host " 当前内核: " -NoNewline
                Write-Host "$processName.exe".PadRight(60) -ForegroundColor Green
                Write-Host " 运行状态: " -NoNewline
                Write-Host "Running (PID: $($p.Id))".PadRight(60) -ForegroundColor Green
                
                $cpu = "{0:N2}" -f $p.CPU
                $mem = "{0:N2}" -f ($p.WorkingSet64 / 1MB)
                Write-Host " 资源占用: CPU: $cpu s | MEM: $mem MB".PadRight(60)
                Write-Host " 控制端口: $(Get-ControllerPort)".PadRight(60)
                Write-Host "".PadRight(60)
            }
            Write-Host "----------------------------------------".PadRight(60) -ForegroundColor DarkGray
            
            Start-Sleep -Milliseconds 800
        }
    }
    catch {
        # 用户按 Ctrl+C 退出
    }
    finally {
        try { $Host.UI.RawUI.CursorSize = $oldCursorSize } catch {}
        [Console]::SetCursorPosition(0, $originY + 8)
        Write-Host "`n 监控已结束。" -ForegroundColor Yellow
    }
}

function Open-UI {
    $port = Get-ControllerPort
    $ui = Get-UIPath
    $url = "http://127.0.0.1:$port/$ui"
    Write-Host "[$currentCore] 打开 UI: $url" -ForegroundColor Cyan
    try { 
        Invoke-WebRequest -Uri "http://127.0.0.1:$port" -TimeoutSec 1 -UseBasicParsing | Out-Null 
    } catch { 
        Start-Core; Start-Sleep 1 
    }
    Start-Process $url
}

function Show-Help {
    Write-Host ""
    Write-Host " Core 管理工具" -ForegroundColor Cyan
    Write-Host "----------------------------------------" -ForegroundColor DarkGray

    $p = Get-Process -Name $processName -ErrorAction SilentlyContinue

    Write-Host " 当前内核: " -NoNewline

    if (!$p) {
        Write-Host "$currentCore 未运行（运行: core start）" -ForegroundColor Red
    } else {
        Write-Host "$currentCore (PID: $($p.Id)) is Running" -ForegroundColor Green
    }

    Write-Host ""
    Write-Host " 可切换内核:" 

    if (Test-Path $root) {
        Get-ChildItem $root | Where-Object { $_.PSIsContainer } | ForEach-Object {
            $status = Get-FolderStatus $_.Name
            if ($status.exe) {

                $isCurrent = $_.Name -eq $currentCore
                $prefix = if ($isCurrent) { "   * " } else { "     " }

                if ($status.isValid) {
                    if ($isCurrent) {
                        Write-Host "$prefix$($_.Name)" -ForegroundColor Green
                    } else {
                        Write-Host "$prefix$($_.Name)"
                    }
                } else {
                    Write-Host "$prefix$($_.Name) (配置缺失)" -ForegroundColor DarkGray
                }
            }
        }
    } else {
        Write-Host "     错误: 找不到根目录 $root" -ForegroundColor Red
    }

    Write-Host ""
    Write-Host " core 子命令:" -ForegroundColor Magenta

    Write-Host "   [name]    " -NoNewline
    Write-Host "—— 切换目标内核" -ForegroundColor DarkGray

    Write-Host "   start     " -NoNewline
    Write-Host "—— 启动当前内核" -ForegroundColor DarkGray

    Write-Host "   stop      " -NoNewline
    Write-Host "—— 停止当前内核" -ForegroundColor DarkGray

    Write-Host "   restart   " -NoNewline
    Write-Host "—— 重启当前内核" -ForegroundColor DarkGray

    Write-Host "   status    " -NoNewline
    Write-Host "—— 查看当前状态" -ForegroundColor DarkGray

    Write-Host "   watch     " -NoNewline
    Write-Host "—— 实时监控面板" -ForegroundColor DarkGray

    Write-Host "   ui        " -NoNewline
    Write-Host "—— 打开控制面板" -ForegroundColor DarkGray

    Write-Host "----------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
}

# ------------------------
# 逻辑入口
# ------------------------

if ([string]::IsNullOrEmpty($cmd)) {
    Show-Help
} else {
    $targetInfo = Get-FolderStatus $cmd
    # 1. 如果匹配到是内核名称，尝试执行“切换”逻辑
    if ($targetInfo -and $targetInfo.exe) {
        
        # --- 切换内核前须先通过权限检查 ---
        if (-not (Assert-Admin)) {
            Write-Host ""
            return 
        }

        if (!$targetInfo.isValid) {
            Write-Host "无法切换: $cmd 缺少 *.yaml/*.json 配置文件" -ForegroundColor Red
            return
        }

        if ($cmd -eq $currentCore) {
            Write-Host "当前已是 $cmd" -ForegroundColor Yellow
        } else {
            if (Stop-Core) {
                $cmd | Out-File $coreFile -Encoding ascii
                Write-Host "已切换 → $cmd" -ForegroundColor Green
                
                # 启动内核
                Start-Core 

                Write-Host "按 u 打开 WebUI (5秒内有效)..." -ForegroundColor Cyan
                $startTime = Get-Date
                while ((Get-Date) - $startTime -lt (New-TimeSpan -Seconds 5)) {
                    if ([Console]::KeyAvailable) {
                        if ([Console]::ReadKey($true).KeyChar -eq 'u') { 
                            Open-UI
                            break 
                        }
                    }
                    Start-Sleep -Milliseconds 100
                }
            } else {
                Write-Host "由于无法停止旧进程，切换已中止。" -ForegroundColor Red
            }
        }
    } 
    # 2. 如果是普通子命令
    else {
        switch ($cmd) {
            "start"   { Start-Core }
            "stop"    { Stop-Core }
            "restart" { Restart-Core }
            "status"  { Status-Core }
            "watch"   { Watch-Core }
            "ui"      { Open-UI }
            default   { Show-Help }
        }
    }
}
