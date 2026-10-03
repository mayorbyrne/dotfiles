# ~/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1

Import-Module posh-git
Import-Module PSReadLine
Set-PSReadLineOption -PredictionSource None

# PS 7 is already UTF-8. Re-assigning encoding here can poke ConPTY and
# leave the cursor on the last column (C:\ wraps, typed chars ghost).
if ($PSVersionTable.PSVersion.Major -lt 6) {
  $utf8 = New-Object System.Text.UTF8Encoding $false
  [Console]::InputEncoding = $utf8
  [Console]::OutputEncoding = $utf8
  $OutputEncoding = $utf8
}

# WezTerm/ConPTY often reports X at the wrap column after a startup resize.
$PoshGitPrompt = $function:prompt
function prompt {
  try {
    $ui = $Host.UI.RawUI
    $cursor = $ui.CursorPosition
    if ($cursor.X -ne 0) {
      $cursor.X = 0
      $ui.CursorPosition = $cursor
    }
  } catch {
  }
  & $PoshGitPrompt
}

function git-checkout { git checkout $args }
Set-Alias -Name gcc -Value git-checkout

function git-status { git status }
Set-Alias -Name gs -Value git-status

function git-fetch-prune { git fetch -p}
Set-Alias -Name gfp -Value git-fetch-prune

function git-reset-hard { git reset --hard }
Set-Alias -Name grh -Value git-reset-hard

function git-commit-no-verify { git commit --no-verify }
Set-Alias -Name gcv -Value git-commit-no-verify

# Strip NO_COLOR inherited from a parent process (it disables color in lazygit, etc)
Remove-Item Env:NO_COLOR -ErrorAction SilentlyContinue
