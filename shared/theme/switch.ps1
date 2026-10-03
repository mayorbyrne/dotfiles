# Usage: switch.ps1 elforest|classic
param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("elforest", "classic")]
  [string]$Theme
)

$dotfiles = "$env:USERPROFILE\.dotfiles\shared"
$lazygit = "$dotfiles\lazygit\Library\Application Support\lazygit\config.yml"
$flavor = if ($Theme -eq "classic") { "catppuccin-mocha" } else { "elforest" }

function Write-Lf([string]$Path, [string[]]$Lines) {
  [IO.File]::WriteAllText($Path, (($Lines -join "`n") + "`n"))
}

Write-Lf "$dotfiles\theme\theme.txt" @($Theme)
Write-Lf "$dotfiles\yazi\.config\yazi\theme.toml" @("[flavor]", "dark = `"$flavor`"", "light = `"$flavor`"")

# Classic had no lazygit theme, so the block is commented out rather than swapped.
$inBlock = $false
$lines = foreach ($line in [IO.File]::ReadAllLines($lazygit)) {
  if ($line -match "# theme:start") { $inBlock = $true; $line; continue }
  if ($line -match "# theme:end") { $inBlock = $false; $line; continue }
  if (-not $inBlock) { $line; continue }
  $plain = $line -replace "^#~", ""
  if ($Theme -eq "classic") { "#~$plain" } else { $plain }
}
Write-Lf $lazygit $lines

Write-Host "Theme set to $Theme. Reload wezterm (save .wezterm.lua or restart), then reopen nvim, yazi, lazygit."
