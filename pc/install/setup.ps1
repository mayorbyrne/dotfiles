# Windows PC Setup Script
# Double-click setup.bat to run this script

$Host.UI.RawUI.WindowTitle = "PC Setup Script"

trap {
    Write-Host ""
    Write-Host "ERROR OCCURRED!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Read-Host "Press Enter to exit"
    Exit 1
}

$ErrorActionPreference = "Stop"

# refreshenv.cmd runs in a child cmd and never updates this PowerShell session
function Update-SessionPath {
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = "$machinePath;$userPath"
}

function Get-GccVersion {
    param([Parameter(Mandatory = $true)][string]$GccPath)
    try {
        $raw = & $GccPath -dumpversion 2>$null
        if ("$raw" -match '^(\d+)\.(\d+)(?:\.(\d+))?') {
            $patch = if ($Matches[3]) { $Matches[3] } else { "0" }
            return [version]"$($Matches[1]).$($Matches[2]).$patch"
        }
    } catch {
    }
    return [version]"0.0.0"
}

function Remove-EnvPathEntries {
    param(
        [Parameter(Mandatory = $true)][ValidateSet("Machine", "User")][string]$Scope,
        [Parameter(Mandatory = $true)][string[]]$Entries
    )
    $current = [Environment]::GetEnvironmentVariable("Path", $Scope)
    if ([string]::IsNullOrEmpty($current)) {
        return
    }
    $remove = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($entry in $Entries) {
        if ($entry) { [void]$remove.Add($entry.TrimEnd("\")) }
    }
    $kept = $current -split ";" | Where-Object { $_ -and -not $remove.Contains($_.TrimEnd("\")) }
    [Environment]::SetEnvironmentVariable("Path", ($kept -join ";"), $Scope)
}

function Add-EnvPathEntry {
    param(
        [Parameter(Mandatory = $true)][ValidateSet("Machine", "User")][string]$Scope,
        [Parameter(Mandatory = $true)][string]$Entry
    )
    $current = [Environment]::GetEnvironmentVariable("Path", $Scope)
    $parts = @()
    if ($current) {
        $parts = $current -split ";" | Where-Object { $_ }
    }
    $already = $parts | Where-Object { $_.TrimEnd("\") -eq $Entry.TrimEnd("\") }
    if (-not $already) {
        [Environment]::SetEnvironmentVariable("Path", ($Entry + ";" + ($parts -join ";")), $Scope)
    }
}

# Chocolatey mingw extracts to $ProgramData\mingw64\mingw64\bin. If that folder
# already holds an older toolchain (13.2 from 2023 is common), the package's
# Move-Item nests the new one under install\mingw64 and then PATHs the leftover.
function Repair-MingwToolchain {
    Write-Host "Ensuring MinGW gcc is current and on PATH..." -ForegroundColor Green
    choco upgrade -y mingw --limit-output

    $searchRoots = @(
        "$env:ProgramData\mingw64",
        "$env:ChocolateyInstall\lib\mingw\tools"
    ) | Where-Object { $_ -and (Test-Path $_) }

    $gccs = foreach ($root in $searchRoots) {
        Get-ChildItem -Path $root -Filter gcc.exe -Recurse -ErrorAction SilentlyContinue
    }
    if (-not $gccs) {
        throw "mingw is installed but gcc.exe was not found under $env:ProgramData\mingw64"
    }

    $best = $gccs | ForEach-Object {
        [pscustomobject]@{ File = $_; Version = (Get-GccVersion $_.FullName) }
    } | Sort-Object Version -Descending | Select-Object -First 1

    $bestBin = $best.File.DirectoryName
    $canonicalRoot = Join-Path $env:ProgramData "mingw64"
    $canonicalBin = Join-Path $canonicalRoot "mingw64\bin"
    $canonicalGcc = Join-Path $canonicalBin "gcc.exe"

    if ($bestBin -ne $canonicalBin) {
        $bestMingw64 = Split-Path $bestBin -Parent
        if ((Test-Path $canonicalGcc) -and ((Get-GccVersion $canonicalGcc) -lt $best.Version)) {
            Write-Host "  Removing leftover MinGW $(Get-GccVersion $canonicalGcc) at $canonicalBin" -ForegroundColor Gray
            Remove-Item -LiteralPath (Join-Path $canonicalRoot "mingw64") -Recurse -Force
        }
        if (-not (Test-Path $canonicalGcc)) {
            try {
                Write-Host "  Moving MinGW $($best.Version) to $canonicalBin" -ForegroundColor Gray
                New-Item -ItemType Directory -Path $canonicalRoot -Force | Out-Null
                Move-Item -LiteralPath $bestMingw64 -Destination (Join-Path $canonicalRoot "mingw64")
                $bestBin = $canonicalBin
                $installLeftover = Join-Path $canonicalRoot "install"
                if (Test-Path $installLeftover) {
                    Remove-Item -LiteralPath $installLeftover -Recurse -Force -ErrorAction SilentlyContinue
                }
            } catch {
                Write-Host "  Could not relocate MinGW; will PATH $bestBin instead: $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
    }

    $mingwBins = @($bestBin)
    if (Test-Path $canonicalRoot) {
        $mingwBins += @(
            Get-ChildItem -Path $canonicalRoot -Filter gcc.exe -Recurse -ErrorAction SilentlyContinue |
                ForEach-Object { $_.DirectoryName }
        )
    }
    $mingwBins = $mingwBins | Where-Object { $_ } | Select-Object -Unique

    foreach ($scope in @("Machine", "User")) {
        Remove-EnvPathEntries -Scope $scope -Entries $mingwBins
    }
    Add-EnvPathEntry -Scope "Machine" -Entry $bestBin

    $sessionParts = $env:Path -split ";" | Where-Object {
        $_ -and ($mingwBins -notcontains $_.TrimEnd("\"))
    }
    $env:Path = $bestBin + ";" + ($sessionParts -join ";")

    $activeGcc = (Get-Command gcc.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1).Source
    $activeVer = if ($activeGcc) { Get-GccVersion $activeGcc } else { [version]"0.0.0" }
    Write-Host "  Using gcc $activeVer ($activeGcc)" -ForegroundColor Green
    if ($activeVer -lt [version]"14.0.0") {
        Write-Host "  Warning: gcc older than 14 cannot compile nvim-treesitter parsers (ld rejects \\?\ paths)" -ForegroundColor Yellow
    }
}

function New-RunProgramRemap {
    param(
        [Parameter(Mandatory = $true)][string]$OriginalKeys,
        [Parameter(Mandatory = $true)][string]$FilePath,
        [string]$Arguments = ""
    )
    return [pscustomobject]@{
        originalKeys                   = $OriginalKeys
        exactMatch                     = $false
        operationType                  = 1
        runProgramFilePath             = $FilePath
        runProgramArgs                 = $Arguments
        runProgramStartInDir           = Split-Path $FilePath -Parent
        runProgramElevationLevel       = 0
        runProgramAlreadyRunningAction = 1
        runProgramStartWindowType      = 0
        unicodeText                    = "*Unsupported*"
    }
}

if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Restarting as Administrator..." -ForegroundColor Yellow
    Start-Sleep -Seconds 2
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

Write-Host "PC Setup Script - Starting Installation" -ForegroundColor Cyan
Write-Host ""

$dotfilesDir = "$env:USERPROFILE\.dotfiles"
if (!(Test-Path $dotfilesDir)) {
    Write-Host "Cloning dotfiles..." -ForegroundColor Green
    git clone https://www.github.com/mayorbyrne/dotfiles.git $dotfilesDir
} else {
    Write-Host "Dotfiles directory already exists" -ForegroundColor Gray
}

if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey..." -ForegroundColor Green
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    Update-SessionPath
} else {
    Write-Host "Chocolatey already installed" -ForegroundColor Gray
}

Write-Host "Installing packages via Chocolatey..." -ForegroundColor Green
Write-Host "This may take several minutes. Please be patient..." -ForegroundColor Yellow

$packages = @("git", "neovim", "yazi", "fzf", "ripgrep", "powershell-core", "powertoys", "tree-sitter", "mingw", "sed", "python", "azure-cli", "jq")
foreach ($package in $packages) {
    Write-Host "Installing $package..." -ForegroundColor Gray
    choco install -y $package --limit-output
    Start-Sleep -Seconds 3
}

# Stable 20240203 (the only choco version) flickers the cursor under synchronized output
Write-Host "Installing WezTerm nightly..." -ForegroundColor Green
winget install --exact --id wez.wezterm.nightly --silent --accept-source-agreements --accept-package-agreements

# scoop bucket add shells out to the git choco just installed
Update-SessionPath
Repair-MingwToolchain

if (Get-Command az -ErrorAction SilentlyContinue) {
    Write-Host "Adding az devops extension..." -ForegroundColor Green
    az extension add --name azure-devops --upgrade --only-show-errors
}

if (!(Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Scoop..." -ForegroundColor Green
    # This script runs elevated, and the Scoop installer refuses admin without -RunAsAdmin
    iex "& {$(irm get.scoop.sh)} -RunAsAdmin"
} else {
    Write-Host "Scoop already installed" -ForegroundColor Gray
}

if (Test-Path "$env:ChocolateyInstall\lib\lazygit") {
    Write-Host "Removing Chocolatey lazygit..." -ForegroundColor Green
    choco uninstall -y lazygit --limit-output
}

Write-Host "Installing lazygit via Scoop..." -ForegroundColor Green
scoop bucket add extras
scoop install lazygit

if (!(Get-Command nvm -ErrorAction SilentlyContinue)) {
    Write-Host "Installing nvm-windows..." -ForegroundColor Green
    $nvmInstaller = "$env:TEMP\nvm-setup.exe"
    Invoke-WebRequest -Uri "https://github.com/coreybutler/nvm-windows/releases/download/1.1.12/nvm-setup.exe" -OutFile $nvmInstaller
    Start-Process -FilePath $nvmInstaller -ArgumentList "/VERYSILENT" -Wait
    Remove-Item $nvmInstaller
    
    Write-Host "Refreshing environment for nvm..." -ForegroundColor Green
    $env:NVM_HOME = "$env:APPDATA\nvm"
    $env:NVM_SYMLINK = "$env:ProgramFiles\nodejs"
    $env:Path = "$env:NVM_HOME;$env:NVM_SYMLINK;$env:Path"
}

Write-Host "Installing Node.js LTS..." -ForegroundColor Green
nvm install lts
nvm use lts

Write-Host "Installing GitHub Copilot CLI..." -ForegroundColor Green
npm install -g @githubnext/github-copilot-cli

Write-Host "Installing PowerShell modules..." -ForegroundColor Green
Install-Module -Name posh-git -Scope CurrentUser -Force -SkipPublisherCheck
Install-Module -Name PSReadLine -Scope CurrentUser -Force -SkipPublisherCheck
# This script runs in Windows PowerShell 5, whose module dir pwsh 7 does not search. PSReadLine ships with pwsh.
pwsh -NoProfile -Command "Install-Module -Name posh-git -Scope CurrentUser -Force -SkipPublisherCheck"

$nvimTarget = "$env:LOCALAPPDATA\nvim"
$nvimSource = "$dotfilesDir\pc\nvim\.config\nvim"

if (Test-Path $nvimTarget) {
    Remove-Item -Path $nvimTarget -Recurse -Force
}

Write-Host "Creating nvim symlink..." -ForegroundColor Green
New-Item -ItemType SymbolicLink -Path $nvimTarget -Target $nvimSource -Force | Out-Null

Write-Host "Installing nvim plugins from lazy-lock.json..." -ForegroundColor Green
nvim --headless "+Lazy! restore" +qa

Write-Host "Building treesitter parsers..." -ForegroundColor Green
# force: an unforced install can report success yet write no parsers
nvim --headless -c "lua require('nvim-treesitter').install(require('lazy.core.config').plugins['nvim-treesitter'].opts.parsers, { force = true, summary = true }):wait(900000)" +qa

# PowerShell profile for both PowerShell 5 and PowerShell 6+
$psProfileSource = "$dotfilesDir\pc\powershell\Microsoft.PowerShell_profile.ps1"

# PowerShell 5 (WindowsPowerShell)
$psProfileDir5 = "$env:USERPROFILE\Documents\WindowsPowerShell"
$psProfileTarget5 = "$psProfileDir5\Microsoft.PowerShell_profile.ps1"

if (!(Test-Path $psProfileDir5)) {
    New-Item -ItemType Directory -Path $psProfileDir5 -Force | Out-Null
}

if (Test-Path $psProfileTarget5) {
    Remove-Item -Path $psProfileTarget5 -Force
}

Write-Host "Creating PowerShell 5 profile symlink..." -ForegroundColor Green
New-Item -ItemType SymbolicLink -Path $psProfileTarget5 -Target $psProfileSource -Force | Out-Null

# PowerShell 6+ (PowerShell Core)
$psProfileDir6 = "$env:USERPROFILE\Documents\PowerShell"
$psProfileTarget6 = "$psProfileDir6\Microsoft.PowerShell_profile.ps1"

if (!(Test-Path $psProfileDir6)) {
    New-Item -ItemType Directory -Path $psProfileDir6 -Force | Out-Null
}

if (Test-Path $psProfileTarget6) {
    Remove-Item -Path $psProfileTarget6 -Force
}

Write-Host "Creating PowerShell 6+ profile symlink..." -ForegroundColor Green
New-Item -ItemType SymbolicLink -Path $psProfileTarget6 -Target $psProfileSource -Force | Out-Null

$weztermTarget = "$env:USERPROFILE\.wezterm.lua"
$weztermSource = "$dotfilesDir\shared\wezterm\.wezterm.lua"

if (Test-Path $weztermTarget) {
    Remove-Item -Path $weztermTarget -Force
}

Write-Host "Creating wezterm config symlink..." -ForegroundColor Green
New-Item -ItemType SymbolicLink -Path $weztermTarget -Target $weztermSource -Force | Out-Null

$lazygitConfigDir = "$env:APPDATA\lazygit"
$lazygitTarget = "$lazygitConfigDir\config.yml"
$lazygitSource = "$dotfilesDir\shared\lazygit\Library\Application Support\lazygit\config.yml"

if (!(Test-Path $lazygitConfigDir)) {
    New-Item -ItemType Directory -Path $lazygitConfigDir -Force | Out-Null
}

if (Test-Path $lazygitTarget) {
    Remove-Item -Path $lazygitTarget -Force
}

Write-Host "Creating lazygit config symlink..." -ForegroundColor Green
New-Item -ItemType SymbolicLink -Path $lazygitTarget -Target $lazygitSource -Force | Out-Null

$yaziConfigDir = "$env:APPDATA\yazi\config"
$yaziSource = "$dotfilesDir\shared\yazi\.config\yazi"

if (Test-Path $yaziConfigDir) {
    Remove-Item -Path $yaziConfigDir -Recurse -Force
}

Write-Host "Creating yazi config symlink..." -ForegroundColor Green
New-Item -ItemType SymbolicLink -Path $yaziConfigDir -Target $yaziSource -Force | Out-Null

$starshipConfigDir = "$env:USERPROFILE\.config"
$starshipTarget = "$starshipConfigDir\starship.toml"
$starshipSource = "$dotfilesDir\shared\starship\.config\starship.toml"

if (!(Test-Path $starshipConfigDir)) {
    New-Item -ItemType Directory -Path $starshipConfigDir -Force | Out-Null
}

if (Test-Path $starshipTarget) {
    Remove-Item -Path $starshipTarget -Force
}

Write-Host "Creating starship config symlink..." -ForegroundColor Green
New-Item -ItemType SymbolicLink -Path $starshipTarget -Target $starshipSource -Force | Out-Null

$muxConfigDir = "$env:USERPROFILE\.config\scripts"
$muxTarget = "$muxConfigDir\mux.sh"
$muxSource = "$dotfilesDir\shared\scripts\.config\scripts\mux.sh"

if (!(Test-Path $muxConfigDir)) {
    New-Item -ItemType Directory -Path $muxConfigDir -Force | Out-Null
}

if (Test-Path $muxTarget) {
    Remove-Item -Path $muxTarget -Force
}

Write-Host "Creating mux.sh symlink..." -ForegroundColor Green
New-Item -ItemType SymbolicLink -Path $muxTarget -Target $muxSource -Force | Out-Null

$scriptsDir = "$env:USERPROFILE\scripts"
if (!(Test-Path $scriptsDir)) {
    Write-Host "Cloning scripts..." -ForegroundColor Green
    git clone https://github.com/kevin-alt-acct/scripts.git $scriptsDir
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  Warning: scripts clone failed; Win+Shift+P stays dead until $scriptsDir exists" -ForegroundColor Yellow
    }
} else {
    Write-Host "Scripts directory already exists" -ForegroundColor Gray
}

Write-Host "Setting up hotkey host..." -ForegroundColor Green
$hotkeyHostDir = Join-Path $dotfilesDir "pc\hotkey-host"
$hotkeyHostScript = Join-Path $hotkeyHostDir "hotkey.ps1"
$triggerExe = Join-Path $hotkeyHostDir "lib\trigger.exe"
# With Windows Terminal as default terminal, -WindowStyle Hidden only minimizes, leaving a taskbar entry. Headless conhost never makes a window.
$hotkeyHostExe = "$env:WINDIR\System32\conhost.exe"
$hotkeyHostArgs = "--headless `"$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe`" -NoProfile -ExecutionPolicy Bypass -Sta -File `"$hotkeyHostScript`""
try {
    & (Join-Path $hotkeyHostDir "build.ps1")

    $startupLnk = Join-Path ([Environment]::GetFolderPath("Startup")) "WeztermHotkey.lnk"
    $shortcut = (New-Object -ComObject WScript.Shell).CreateShortcut($startupLnk)
    $shortcut.TargetPath = $hotkeyHostExe
    $shortcut.Arguments = $hotkeyHostArgs
    $shortcut.WorkingDirectory = $hotkeyHostDir
    $shortcut.Save()

    # Launching the host replaces any running instance.
    Start-Process $hotkeyHostExe -ArgumentList $hotkeyHostArgs -WorkingDirectory $hotkeyHostDir
    Write-Host "  Built lib\, added Startup shortcut, started host" -ForegroundColor Green
} catch {
    Write-Host "  Warning: hotkey host setup failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "Configuring PowerToys Win+Shift+R -> wezterm-launcher, Win+Shift+P -> script-selector..." -ForegroundColor Green
try {
    $powerToysDir = Join-Path $dotfilesDir "pc\powertoys"
    . (Join-Path $powerToysDir "PowerToysSettings.ps1")
    $kbmDir = Join-Path $powerToysRoot "Keyboard Manager"
    $kbmSettingsPath = Join-Path $kbmDir "settings.json"
    $kbmDefaultPath = Join-Path $kbmDir "default.json"
    $launcherBat = Join-Path $dotfilesDir "pc\wezterm-launcher\launch.bat"

    # Win+Shift+R and Win+Shift+P as PowerToys UI serializes them (VK_WIN_BOTH=260, VK_SHIFT=16, R=82, P=80)
    $launcherKeys = "260;16;82"
    $scriptsKeys = "260;16;80"
    # trigger.exe wakes the resident host, opening the launcher in ~0.2s vs ~2.5s for launch.bat.
    $hasTrigger = Test-Path $triggerExe
    $hotkeyRemaps = @(
        if ($hasTrigger) {
            New-RunProgramRemap -OriginalKeys $launcherKeys -FilePath $triggerExe -Arguments "launcher"
            New-RunProgramRemap -OriginalKeys $scriptsKeys -FilePath $triggerExe -Arguments "scripts"
        } else {
            New-RunProgramRemap -OriginalKeys $launcherKeys -FilePath $launcherBat
        }
    )
    # Older files spell the same combos with VK_LWIN=91 and VK_LSHIFT=160.
    $hotkeyKeys = @($hotkeyRemaps | ForEach-Object { $_.originalKeys; $_.originalKeys -replace '^260;16;', '91;160;' })

    New-Item -ItemType Directory -Path $kbmDir -Force | Out-Null

    # Shortcut remaps kept in dotfiles; they replace any existing remap on the same keys (and app).
    $dotfileRemaps = Read-JsonFile (Join-Path $powerToysDir "remaps.json")
    $dotfileGlobal = @(if ($dotfileRemaps) { $dotfileRemaps.global })
    $dotfileAppSpecific = @(if ($dotfileRemaps) { $dotfileRemaps.appSpecific })
    $dotfileGlobalKeys = @($dotfileGlobal | ForEach-Object { $_.originalKeys })
    $dotfileAppSpecificKeys = @($dotfileAppSpecific | ForEach-Object { "$($_.targetApp)|$($_.originalKeys)" })

    $existingKbm = Read-JsonFile $kbmDefaultPath
    $globalRemaps = [System.Collections.Generic.List[object]]::new()
    $appSpecificRemaps = [System.Collections.Generic.List[object]]::new()
    if ($existingKbm -and $existingKbm.remapShortcuts -and $existingKbm.remapShortcuts.global) {
        foreach ($remap in @($existingKbm.remapShortcuts.global)) {
            if (-not $remap) { continue }
            if ($hotkeyKeys -contains $remap.originalKeys) { continue }
            if ($dotfileGlobalKeys -contains $remap.originalKeys) { continue }
            # Hand-made bindings to other host targets follow trigger.exe to this checkout.
            if ($hasTrigger -and $remap.runProgramFilePath -and (Split-Path $remap.runProgramFilePath -Leaf) -eq "trigger.exe") {
                $remap.runProgramFilePath = $triggerExe
                if ($remap.runProgramStartInDir) { $remap.runProgramStartInDir = Split-Path $triggerExe -Parent }
            }
            $globalRemaps.Add($remap)
        }
    }
    if ($existingKbm -and $existingKbm.remapShortcuts -and $existingKbm.remapShortcuts.appSpecific) {
        foreach ($remap in @($existingKbm.remapShortcuts.appSpecific)) {
            if (-not $remap) { continue }
            if ($dotfileAppSpecificKeys -contains "$($remap.targetApp)|$($remap.originalKeys)") { continue }
            $appSpecificRemaps.Add($remap)
        }
    }
    foreach ($remap in $dotfileGlobal) { $globalRemaps.Add($remap) }
    foreach ($remap in $dotfileAppSpecific) { $appSpecificRemaps.Add($remap) }
    foreach ($remap in $hotkeyRemaps) { $globalRemaps.Add($remap) }

    $kbmConfig = [pscustomobject]@{
        remapKeys            = if ($existingKbm -and $existingKbm.remapKeys) { $existingKbm.remapKeys } else { [pscustomobject]@{ inProcess = @() } }
        remapKeysToText      = if ($existingKbm -and $existingKbm.remapKeysToText) { $existingKbm.remapKeysToText } else { [pscustomobject]@{ inProcess = @() } }
        remapShortcuts       = [pscustomobject]@{
            global      = @($globalRemaps.ToArray())
            appSpecific = @($appSpecificRemaps.ToArray())
        }
        remapShortcutsToText = if ($existingKbm -and $existingKbm.remapShortcutsToText) {
            $existingKbm.remapShortcutsToText
        } else {
            [pscustomobject]@{ global = @(); appSpecific = @() }
        }
    }
    Write-JsonFile $kbmDefaultPath $kbmConfig

    $kbmModuleSettings = Read-JsonFile $kbmSettingsPath
    if (-not $kbmModuleSettings) {
        $kbmModuleSettings = [pscustomobject]@{
            name       = "Keyboard Manager"
            properties = [pscustomobject]@{
                activeConfiguration = [pscustomobject]@{ value = "default" }
            }
        }
    } else {
        if (-not $kbmModuleSettings.properties) {
            $kbmModuleSettings | Add-Member -NotePropertyName properties -NotePropertyValue ([pscustomobject]@{}) -Force
        }
        $kbmModuleSettings.properties | Add-Member -NotePropertyName activeConfiguration -NotePropertyValue ([pscustomobject]@{ value = "default" }) -Force
    }
    Write-JsonFile $kbmSettingsPath $kbmModuleSettings

    & (Join-Path $powerToysDir "register-guard.ps1")

    Restart-PowerToys
    Start-Sleep -Seconds 4
    if (-not (Test-KeyboardManagerEnabled)) {
        Restart-PowerToys
        Start-Sleep -Seconds 3
    }
    $engine = Get-Process -Name "PowerToys.KeyboardManagerEngine" -ErrorAction SilentlyContinue
    if ($engine) {
        Write-Host "  Keyboard Manager on; Win+Shift+R -> wezterm-launcher; Win+Shift+P -> script-selector; logon guard registered" -ForegroundColor Green
    } else {
        Write-Host "  PowerToys started but Keyboard Manager engine not seen yet - open PowerToys settings and enable Keyboard Manager" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  Warning: PowerToys hotkey setup failed: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "  You can set Win+Shift+R and Win+Shift+P manually in PowerToys > Keyboard Manager > Remap a shortcut" -ForegroundColor Yellow
}

Write-Host "Installing FiraCode Nerd Font..." -ForegroundColor Green
$fontPath = "$dotfilesDir\shared\fonts\FiraCode Nerd Font-Regular.ttf"
$FONTS = 0x14
$objShell = New-Object -ComObject Shell.Application
$objFolder = $objShell.Namespace($FONTS)
$objFolder.CopyHere($fontPath, 0x10)

$aiClisSetup = "$dotfilesDir\shared\install\setup_ai_clis.ps1"
if (Test-Path $aiClisSetup) {
    & $aiClisSetup
}

$aiConfigSetup = "$dotfilesDir\shared\install\setup_ai_config.ps1"
if (Test-Path $aiConfigSetup) {
    & $aiConfigSetup
}

Write-Host ""
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "Restart your terminal and run 'nvim'" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Run 'shared\install\setup_git.ps1' to configure git user and credentials" -ForegroundColor Yellow
Write-Host "2. Run 'shared\install\setup_azure.ps1' to configure Azure DevOps defaults, reviewers, and token" -ForegroundColor Yellow
Write-Host "3. Press Win+Shift+R to open wezterm-launcher, Win+Shift+P for script-selector (requires PowerToys running)" -ForegroundColor Yellow
Write-Host ""
Read-Host "Press Enter to exit"
