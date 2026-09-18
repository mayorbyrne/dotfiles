# ~/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1

Import-Module posh-git
Import-Module PSReadLine

[Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8
$OutputEncoding = [Text.UTF8Encoding]::UTF8

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
