# Builds the native pieces into lib\:
#
#   Win32Focus.dll  Focus helpers plus the host wait loop. launcher.ps1 loads
#                   this when present; without it PowerShell invokes the C#
#                   compiler on every launch, costing roughly 600ms before the
#                   window can even start painting.
#   trigger.exe     Signals the resident host. PowerToys Keyboard Manager runs
#                   this on Win+Shift+R.
#
# Run this once, and again after editing anything under src\.

$ErrorActionPreference = 'Stop'

$csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (-not (Test-Path $csc)) {
    throw "C# compiler not found at $csc. .NET Framework 4.x is required."
}

$lib = Join-Path $PSScriptRoot 'lib'
if (-not (Test-Path $lib)) { New-Item -ItemType Directory -Path $lib | Out-Null }

$dll = Join-Path $lib 'Win32Focus.dll'
& $csc /nologo /target:library /optimize+ /out:"$dll" (Join-Path $PSScriptRoot 'src\Win32Focus.cs')
if ($LASTEXITCODE -ne 0) { throw "Win32Focus.dll failed to compile (exit code $LASTEXITCODE)." }
Write-Host "Built $dll"

$exe = Join-Path $lib 'trigger.exe'
& $csc /nologo /target:winexe /optimize+ /out:"$exe" (Join-Path $PSScriptRoot 'src\Trigger.cs')
if ($LASTEXITCODE -ne 0) { throw "trigger.exe failed to compile (exit code $LASTEXITCODE)." }
Write-Host "Built $exe"
