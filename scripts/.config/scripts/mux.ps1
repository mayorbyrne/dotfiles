# this should be unnecessary with the wezterm setup

param (
    [string]$ProjectName,
    [int]$Port = 8080
)

if (-not $ProjectName) {
    Write-Host "Valid project name required"
    exit 1
}

if (-not $Port) {
    Write-Host "Port not specified, defaulting to 8080"
}

$SessionName = $ProjectName

wt.exe nt -d d:/git/gradebook nvim ; -d d:/git/gradebook powershell -noExit "npm run dev-prod" ; -d d:/git/gradebook lazygit
