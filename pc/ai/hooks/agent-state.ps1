# Writes ~/.config/wezterm/agent_state.txt for WezTerm tab/status badges.
# Claude and Cursor hooks call this with -Agent and JSON on stdin.

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("claude", "agent", "codex")]
    [string]$Agent,

    [string]$Event = ""
)

$ErrorActionPreference = "Stop"

function Get-HookPayload {
    $raw = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($raw)) { return $null }
    try {
        return $raw | ConvertFrom-Json
    } catch {
        return $null
    }
}

function Get-HookEvent($payload) {
    if (-not $payload) { return "" }
    foreach ($name in @("hook_event_name", "event", "type")) {
        $value = $payload.$name
        if ($value -is [string] -and $value) { return $value }
    }
    return ""
}

function Get-HookCwd($payload) {
    if ($payload) {
        if ($payload.cwd -is [string] -and $payload.cwd) { return [string]$payload.cwd }
        $roots = $payload.workspace_roots
        if ($roots) {
            $first = @($roots)[0]
            if ($first -is [string] -and $first) { return $first }
        }
    }
    return (Get-Location).Path
}

function Get-AgentStatus([string]$event) {
    switch -Regex ($event) {
        '^(UserPromptSubmit|beforeSubmitPrompt|PreToolUse|preToolUse)$' { return "working" }
        '^(StopFailure|postToolUseFailure)$' { return "error" }
        '^(sessionEnd)$' { return "remove" }
        '^(SessionStart|sessionStart|Stop|stop|afterAgentResponse)$' { return "idle" }
        default { return "" }
    }
}

function Normalize-Cwd([string]$cwd) {
    if (-not $cwd) { return "" }
    return ($cwd -replace '\\', '/').TrimEnd('/').ToLowerInvariant()
}

function Get-WeztermList {
    $wezterm = Join-Path $env:ProgramFiles "WezTerm\wezterm.exe"
    if (-not (Test-Path $wezterm)) { $wezterm = "wezterm" }
    try {
        $json = & $wezterm cli --no-auto-start list --format json 2>$null
        if ($json) { return $json | ConvertFrom-Json }
    } catch {
    }
    return @()
}

function Get-AgentPaneId([string]$agent, [string]$cwd, [string]$stateDir) {
    $fileHit = ""
    $path = Join-Path $stateDir "agent_panes.txt"
    if (Test-Path $path) {
        foreach ($line in Get-Content $path) {
            $parts = $line.Split('|')
            if ($parts.Count -ge 3 -and $parts[0] -eq $agent) {
                $paneCwd = Normalize-Cwd $parts[1]
                $paneId = $parts[2]
                if ($cwd -and $paneCwd -and ($paneCwd -eq $cwd -or $cwd.StartsWith($paneCwd) -or $paneCwd.StartsWith($cwd))) {
                    return $paneId
                }
                if (-not $fileHit) { $fileHit = $paneId }
            } elseif ($parts.Count -eq 2 -and $parts[0] -eq $agent -and $parts[1] -match '^\d+$') {
                $fileHit = $parts[1]
            }
        }
    }

    foreach ($pane in @(Get-WeztermList)) {
        $title = ("$($pane.tab_title) $($pane.title)").ToLowerInvariant()
        $match = $false
        if ($agent -eq "agent" -and ($title -match "cursor agent" -or $title -match "cursor-agent")) { $match = $true }
        if ($agent -eq "claude" -and $title -match "claude") { $match = $true }
        if ($agent -eq "codex" -and $title -match "codex") { $match = $true }
        if (-not $match) { continue }
        $paneCwd = Normalize-Cwd (($pane.cwd -replace '^file://[^/]*/', '/' -replace '^/([A-Za-z]:)', '$1'))
        if ($cwd -and $paneCwd -and ($paneCwd -eq $cwd -or $cwd.StartsWith($paneCwd) -or $paneCwd.StartsWith($cwd))) {
            return [string]$pane.pane_id
        }
        if (-not $fileHit) { $fileHit = [string]$pane.pane_id }
    }

    return $fileHit
}

function Get-WeztermPaneActivateExe([string]$stateDir) {
    return Join-Path $stateDir "WeztermPaneActivate.exe"
}

function Ensure-WeztermPaneActivate([string]$stateDir) {
    $exe = Get-WeztermPaneActivateExe $stateDir
    $source = Join-Path $PSScriptRoot "WeztermPaneActivate.cs"
    if (-not (Test-Path $source)) { return $null }
    $sourceTime = (Get-Item $source).LastWriteTimeUtc
    $needsBuild = -not (Test-Path $exe)
    if (-not $needsBuild) {
        $needsBuild = (Get-Item $exe).LastWriteTimeUtc -lt $sourceTime
    }
    if ($needsBuild) {
        $csc = Join-Path $env:WINDIR "Microsoft.NET\Framework64\v4.0.30319\csc.exe"
        if (-not (Test-Path $csc)) { return $null }
        $fw = Join-Path $env:WINDIR "Microsoft.NET\Framework64\v4.0.30319"
        $runtime = Join-Path $fw "System.Runtime.WindowsRuntime.dll"
        $sysrt = Join-Path $fw "System.Runtime.dll"
        $winmd = Join-Path $env:WINDIR "System32\WinMetadata"
        if (-not (Test-Path $runtime)) { return $null }
        $null = & $csc /nologo /target:winexe /platform:x64 /out:$exe `
            /r:System.dll `
            /r:$sysrt `
            /r:$runtime `
            /r:"$winmd\Windows.Foundation.winmd" `
            /r:"$winmd\Windows.Data.winmd" `
            /r:"$winmd\Windows.UI.winmd" `
            $source
        if (-not (Test-Path $exe)) { return $null }
    }
    $registered = $false
    try {
        $registered = (Get-ItemProperty "HKCU:\Software\Classes\AppUserModelId\Kevin.WezTerm.Agent" -ErrorAction Stop).CustomActivator
    } catch {
    }
    if ($needsBuild -or -not $registered) {
        Start-Process -FilePath $exe -ArgumentList "--register" -Wait -WindowStyle Hidden
    }
    return $exe
}

function Try-ClaimToast([string]$agent, [string]$stateDir) {
    $lock = Join-Path $stateDir "toast.lock.$agent"
    try {
        $fs = [System.IO.File]::Open($lock, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
        $bytes = [System.Text.Encoding]::UTF8.GetBytes([DateTimeOffset]::UtcNow.ToUnixTimeSeconds().ToString())
        $fs.Write($bytes, 0, $bytes.Length)
        $fs.Dispose()
        return $true
    } catch {
        try {
            $age = ([DateTime]::UtcNow - (Get-Item $lock).LastWriteTimeUtc).TotalSeconds
            if ($age -gt 45) {
                Remove-Item $lock -Force -ErrorAction Stop
                return (Try-ClaimToast $agent $stateDir)
            }
        } catch {
        }
        return $false
    }
}

function Show-AgentFinishedToast([string]$agent, [string]$paneId, [string]$stateDir) {
    $exe = Ensure-WeztermPaneActivate $stateDir
    if (-not $exe) { return }
    $notify = @("--notify", "--title", "$agent finished", "--message", "Click to return to the $agent tab")
    if ($paneId -ne "") { $notify += @("--pane", $paneId) }
    & $exe @notify
}

$payload = Get-HookPayload
$event = $Event
if (-not $event) { $event = Get-HookEvent $payload }
$status = Get-AgentStatus $event
if (-not $status) { exit 0 }

$cwd = Normalize-Cwd (Get-HookCwd $payload)
if (-not $cwd) { exit 0 }

$stateDir = Join-Path $env:USERPROFILE ".config\wezterm"
$stateFile = Join-Path $stateDir "agent_state.txt"
if (-not (Test-Path $stateDir)) {
    New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
}

$now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$staleAfter = $now - (6 * 60 * 60)
$lines = [System.Collections.Generic.List[string]]::new()
$key = "$Agent|$cwd"
$previousStatus = ""

if (Test-Path $stateFile) {
    foreach ($line in Get-Content $stateFile) {
        if ($line -match '^\s*#' -or [string]::IsNullOrWhiteSpace($line)) { continue }
        $parts = $line.Split('|')
        if ($parts.Count -lt 4) { continue }
        $lineKey = "$($parts[0])|$($parts[1])"
        if ($lineKey -eq $key) {
            $previousStatus = $parts[2]
            continue
        }
        $updated = 0
        [void][int64]::TryParse($parts[3], [ref]$updated)
        if ($updated -gt 0 -and $updated -lt $staleAfter) { continue }
        $lines.Add($line)
    }
}

if ($status -ne "remove") {
    $lines.Add("$Agent|$cwd|$status|$now")
}

$utf8 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($stateFile, (($lines -join "`n") + "`n"), $utf8)

$finishedEvent = $event -match '^(Stop|stop|afterAgentResponse)$'
if ($previousStatus -eq "working" -and $status -eq "idle" -and $finishedEvent) {
    if (Try-ClaimToast $Agent $stateDir) {
        try {
            Show-AgentFinishedToast -agent $Agent -paneId (Get-AgentPaneId $Agent $cwd $stateDir) -stateDir $stateDir
        } catch {
        }
    }
}
exit 0
