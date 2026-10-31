$powerToysRoot = Join-Path $env:LOCALAPPDATA "Microsoft\PowerToys"
$generalSettingsPath = Join-Path $powerToysRoot "settings.json"
$goodSettingsPath = "$generalSettingsPath.good"

function Read-JsonFile([string]$path) {
    if (-not (Test-Path $path)) { return $null }
    if ((Get-Item $path).Length -le 0) { return $null }
    $raw = Get-Content -Path $path -Raw -ErrorAction Stop
    if ([string]::IsNullOrWhiteSpace($raw)) { return $null }
    return $raw | ConvertFrom-Json -ErrorAction Stop
}

function Write-JsonFile([string]$path, $object) {
    $dir = Split-Path $path -Parent
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $json = $object | ConvertTo-Json -Depth 10
    [System.IO.File]::WriteAllText($path, $json)
}

function Read-JsonFileOrNull([string]$path) {
    try { return Read-JsonFile $path } catch { return $null }
}

function Test-KeyboardManagerEnabled {
    $gs = Read-JsonFileOrNull $generalSettingsPath
    return [bool]($gs -and $gs.enabled -and $gs.enabled.'Keyboard Manager')
}

function Enable-KeyboardManager {
    $gs = Read-JsonFileOrNull $generalSettingsPath
    if (-not (Test-KeyboardManagerEnabled)) {
        # A settings.json that lost Keyboard Manager was most likely reset to defaults, so the last good copy is closer.
        $good = Read-JsonFileOrNull $goodSettingsPath
        if ($good) { $gs = $good }
    }
    if (-not $gs) { $gs = [pscustomobject]@{} }
    if (-not $gs.enabled) {
        $gs | Add-Member -NotePropertyName enabled -NotePropertyValue ([pscustomobject]@{}) -Force
    }
    $gs.enabled | Add-Member -NotePropertyName "Keyboard Manager" -NotePropertyValue $true -Force
    $gs | Add-Member -NotePropertyName startup -NotePropertyValue $true -Force
    # A non-elevated hook never sees keys typed into elevated windows, so hotkeys fall through to Windows there.
    $gs | Add-Member -NotePropertyName run_elevated -NotePropertyValue $true -Force
    Write-JsonFile $generalSettingsPath $gs
}

function Restart-PowerToys {
    $powerToysExe = @(
        "${env:ProgramFiles}\PowerToys\PowerToys.exe",
        "${env:LOCALAPPDATA}\PowerToys\PowerToys.exe"
    ) | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $powerToysExe) { throw "PowerToys.exe not found" }

    Get-Process -Name "PowerToys*" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    # PowerToys may rewrite settings.json on exit, so enable after the stop.
    Enable-KeyboardManager
    # run_elevated makes PowerToys elevate itself, so the launch token does not matter.
    Start-Process explorer.exe -ArgumentList "`"$powerToysExe`""
}
