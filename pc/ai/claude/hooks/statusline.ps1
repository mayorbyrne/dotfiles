$Esc = [char]27
$Reset = "${Esc}[0m"
$Dim = "${Esc}[2m"

$json = $null
try {
    $raw = $input | Out-String
    if (-not [string]::IsNullOrWhiteSpace($raw)) {
        $json = $raw | ConvertFrom-Json
    }
} catch {}

$Dir = if ($json.workspace.current_dir) { $json.workspace.current_dir } else { (Get-Location).Path }
$Parts = @("${Esc}[36m$(Split-Path -Leaf $Dir)${Reset}")

$Branch = $null
try { $Branch = git -C $Dir branch --show-current 2>$null } catch {}
if (-not [string]::IsNullOrWhiteSpace($Branch)) {
    $Parts += "${Esc}[35m$($Branch.Trim())${Reset}"
}

if ($json.model.display_name) {
    $Parts += "${Dim}$($json.model.display_name)${Reset}"
}

$CtxPct = $json.context_window.used_percentage
if ($null -ne $CtxPct) {
    $pct = [int][Math]::Round($CtxPct)
    $color = if ($pct -ge 80) { "${Esc}[38;5;196m" } elseif ($pct -ge 50) { "${Esc}[38;5;226m" } else { "${Esc}[38;5;82m" }
    $Parts += "${color}[CTX:${pct}%]${Reset}"
}

[Console]::Write($Parts -join " ${Dim}|${Reset} ")
