# Needs an elevated shell: the guard runs with highest privileges so it can restart an elevated PowerToys.
$guardScript = Join-Path $PSScriptRoot "guard.ps1"

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$guardScript`""
$trigger = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERDOMAIN\$env:USERNAME"
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 10)

Register-ScheduledTask -TaskPath "\dotfiles\" -TaskName "PowerToys Guard" -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
