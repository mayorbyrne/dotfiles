Import-Module posh-git
Import-Module PSReadLine

Set-PSReadlineOption -PredictionSource None

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

function mobile-web-activities { cd D:\git\VSMobileWebActivities }
Set-Alias -Name mwa -Value mobile-web-activities

function skunkworks { cd D:\git\Skunkworks }
Set-Alias -Name skunk -Value skunkworks

function dart-pub-list { dart pub deps -s compact --no-dev }
Set-Alias -Name dpl -Value dart-pub-list

Set-Alias mux "~/scripts/mux.bat"
fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression

