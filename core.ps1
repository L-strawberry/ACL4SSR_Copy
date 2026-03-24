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
        |   ├── config.json
        |   ├── sing-box.exe
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

# ‼️‼️‼️根目录 (自行修改实际内核文件夹路径)
$root = "D:\app\core"
$coreFile = "$root\.core"

# 默认内核初始化
if (!(Test-Path $coreFile)) {
    "mihomo" | Out-File $coreFile -Encoding ascii
}

# 兼容读取方式
$currentCore = (Get-Content $coreFile | Out-String).Trim()

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
        type     = if ($exe -and $exe.Name -match "sing-box") { "sing-box" } else { "mihomo" }
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
# 核心控制命令
# ------------------------

function Start-Core {
    if (-not (Assert-Admin)) { return } # 检查权限
    
    if (!$currentInfo -or !$currentInfo.isValid) {
        Write-Host "错误: $currentCore 目录配置不完整，无法启动。" -ForegroundColor Red
        return
    }
    if (Get-Process -Name $processName -ErrorAction SilentlyContinue) {
        Write-Host "[$currentCore] 已在运行" -ForegroundColor Yellow
        return
    }
    
    $runArgs = if ($type -eq "mihomo") { "-f `"$config`"" } else { "run -c `"$config`"" }
    Start-Process $exePath -ArgumentList $runArgs -WorkingDirectory $workdir -WindowStyle Hidden
    Write-Host "[$currentCore] 已启动" -ForegroundColor Green
}

function Stop-Core {
    if (-not (Assert-Admin)) { return } # 检查权限
    
    if (!$processName) { return }
    $p = Get-Process -Name $processName -ErrorAction SilentlyContinue
    if (!$p) {
        Write-Host "[$currentCore] 未运行" -ForegroundColor Gray
        return
    }
    $p | Stop-Process -Force
    Write-Host "[$currentCore] 已停止" -ForegroundColor Green
}

function Restart-Core {
    Stop-Core
    Start-Sleep 1
    Start-Core
}

function Status-Core {
    Write-Host ""
    Write-Host " Core 状态" -ForegroundColor Cyan
    Write-Host "----------------------------------------"
    Write-Host " 当前内核: $currentCore" -ForegroundColor Green
    $p = Get-Process -Name $processName -ErrorAction SilentlyContinue
    if (!$p) {
        Write-Host " 状态: Stopped" -ForegroundColor Red
    } else {
        Write-Host " 状态: Running" -ForegroundColor Green
        Write-Host " PID : $($p.Id)"
        Write-Host " 内存: $("{0:N2}" -f ($p.WorkingSet64 / 1MB)) MB"
        if ($config) { Write-Host " 配置文件: $(Split-Path $config -Leaf)" }
    }
    Write-Host " 控制端口: $(Get-ControllerPort)"
    Write-Host "----------------------------------------"
    Write-Host ""
}

function Watch-Core {
    if (!$processName) { 
        Write-Host " 错误: 当前未选定内核或内核未运行" -ForegroundColor Red
        return 
    }
    Write-Host "`n`n`n`n`n`n`n`n"
    $originY = [Console]::CursorTop - 8
    $oldCursorSize = $Host.UI.RawUI.CursorSize
    try { $Host.UI.RawUI.CursorSize = 0 } catch {}

    try {
        while ($true) {
            [Console]::SetCursorPosition(0, $originY)
            Write-Host " Core 实时状态 (按 Ctrl + C 退出)".PadRight(60) -ForegroundColor Cyan
            Write-Host "------------------------------------------------".PadRight(60)
            $p = Get-Process -Name $processName -ErrorAction SilentlyContinue
            if (!$p) {
                Write-Host " 当前内核: $processName.exe".PadRight(60) -ForegroundColor Gray
                Write-Host " 运行状态: Stopped".PadRight(60) -ForegroundColor Red
                Write-Host "".PadRight(60); Write-Host "".PadRight(60); Write-Host "".PadRight(60)
            } else {
                Write-Host " 当前内核: $processName.exe".PadRight(60) -ForegroundColor Green
                Write-Host " 运行状态: Running (PID: $($p.Id))".PadRight(60) -ForegroundColor Green
                $cpu = "{0:N2}" -f $p.CPU
                $mem = "{0:N2}" -f ($p.WorkingSet64 / 1MB)
                Write-Host " 资源占用: CPU: $cpu s | MEM: $mem MB".PadRight(60)
                Write-Host " 控制端口: $(Get-ControllerPort)".PadRight(60)
                Write-Host "".PadRight(60)
            }
            Write-Host "------------------------------------------------".PadRight(60)
            Start-Sleep -Milliseconds 800
        }
    }
    catch {}
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
    Start-Process $url
}

function Show-Help {
    Write-Host ""
    Write-Host " Core 管理工具" -ForegroundColor Cyan
    Write-Host "----------------------------------------"
    Write-Host " 当前内核: $currentCore" -ForegroundColor Green
    Write-Host ""
    Write-Host " 可切换内核:"
    if (Test-Path $root) {
        Get-ChildItem $root | Where-Object { $_.PSIsContainer } | ForEach-Object {
            $status = Get-FolderStatus $_.Name
            if ($status.exe) {
                $prefix = if ($_.Name -eq $currentCore) { "   * " } else { "     " }
                $color = if ($_.Name -eq $currentCore) { "Green" } else { "White" }
                if ($status.isValid) {
                    Write-Host "$prefix$($_.Name)" -ForegroundColor $color
                } else {
                    Write-Host "$prefix$($_.Name) (缺少配置文件)" -ForegroundColor Gray
                }
            }
        }
    }
    Write-Host ""
    Write-Host " core 子命令:"
    Write-Host "   [name]     - 切换启动内核"
    Write-Host "   start      - 启动当前内核"
    Write-Host "   stop       - 停止当前内核"
    Write-Host "   restart    - 重启当前内核"
    Write-Host "   status     - 查看当前状态"
    Write-Host "   watch      - 实时监控面板"
    Write-Host "   ui         - 打开控制面板"
    Write-Host "----------------------------------------"
    Write-Host ""
}

# ------------------------
# 逻辑入口
# ------------------------

if ([string]::IsNullOrEmpty($cmd)) {
    Show-Help
} else {
    $targetInfo = Get-FolderStatus $cmd
    if ($targetInfo -and $targetInfo.exe) {
        if (-not (Assert-Admin)) { return } # 切换内核前检查权限
        
        if (!$targetInfo.isValid) {
            Write-Host "无法切换: $cmd 缺少 *.yaml/*.json 配置文件" -ForegroundColor Red
            return
        }
        if ($cmd -eq $currentCore) {
            Write-Host "当前已是 $cmd" -ForegroundColor Yellow
        } else {
            # 1. 停止旧的
            Stop-Core
            # 2. 修改配置
            $cmd | Out-File $coreFile -Encoding ascii
            Write-Host "已切换 → $cmd" -ForegroundColor Green
            # 3. 递归调用 start (新进程会带权限继续运行)
            powershell -ExecutionPolicy Bypass -File $PSCommandPath start
            
            Write-Host "按 u 打开 WebUI (5秒内有效)..." -ForegroundColor Cyan
            $startTime = Get-Date
            while ((Get-Date) - $startTime -lt (New-TimeSpan -Seconds 5)) {
                if ([Console]::KeyAvailable) {
                    if ([Console]::ReadKey($true).KeyChar -eq 'u') { 
                        powershell -ExecutionPolicy Bypass -File $PSCommandPath ui
                        break 
                    }
                }
                Start-Sleep -Milliseconds 100
            }
        }
    } else {
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
