# Shutdown can kill PowerToys mid-write and leave settings.json empty, which resets it to defaults with Keyboard Manager off.
. (Join-Path $PSScriptRoot "PowerToysSettings.ps1")

$deadline = (Get-Date).AddMinutes(3)
while (-not (Get-Process -Name "PowerToys" -ErrorAction SilentlyContinue) -and (Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 5
}
# PowerToys rewrites settings.json several seconds after launch.
Start-Sleep -Seconds 30

if (Test-KeyboardManagerEnabled) {
    Copy-Item $generalSettingsPath $goodSettingsPath -Force
    return
}

Add-Content -Path (Join-Path $powerToysRoot "guard.log") -Value "$(Get-Date -Format s) Keyboard Manager off, restoring settings"
Restart-PowerToys
