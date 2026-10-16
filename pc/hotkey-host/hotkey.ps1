<#
.SYNOPSIS
    Resident host that opens WPF launcher scripts on demand.

.DESCRIPTION
    Cold-starting PowerShell costs about a second, and loading WPF plus building
    the first window costs more on top of that. This script pays those costs once
    at login for every target in targets.txt, then parks on a set of named events
    and runs the matching script whenever one is signalled. Windows appear in
    roughly a quarter of a second instead of nearly two.

    Combinations like Win+Shift+R and Win+Shift+P cannot be claimed with
    RegisterHotKey, because Windows 11 reserves them. PowerToys Keyboard Manager
    can still intercept them via its low-level keyboard hook, so KBM stays the
    binding and just needs to run lib\trigger.exe with the target name.

    Setup: pc\install\setup.ps1 builds lib\, adds the WeztermHotkey Startup
    shortcut, and points PowerToys at lib\trigger.exe:
      Win+Shift+R  ->  trigger.exe launcher
      Win+Shift+P  ->  trigger.exe scripts (only if bound by hand; setup
                       repoints any existing trigger.exe binding)

    Target scripts are invoked in their own scope, so edits to them take effect on
    the next press. Only changes to this file or to src\ need a rebuild or a
    restart, via -Stop and relaunching.

.PARAMETER Stop
    Signals a running instance to exit, then returns without starting a new one.
#>
[CmdletBinding()]
param(
    [switch]$Stop
)

$ErrorActionPreference = 'Stop'

$MUTEX_NAME       = 'HotkeyHost.Singleton'
$STOP_NAME        = 'HotkeyHost.Stop'
$SHOW_NAME_PREFIX = 'HotkeyHost.Show.'
$logFile          = "$env:APPDATA\wezterm-launcher\hotkey.log"

function Write-Log([string]$message) {
    try {
        $dir = Split-Path $script:logFile
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
        "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  $message" | Add-Content $script:logFile -Encoding UTF8
    } catch {
        # Logging must never take the host down.
    }
}

# All events are auto-reset: a waiter consumes the signal, so a press never
# queues up a second window and a stop never lingers for the next instance.
function New-AutoResetEvent([string]$name) {
    [System.Threading.EventWaitHandle]::new(
        $false, [System.Threading.EventResetMode]::AutoReset, $name)
}

$stopEvent = New-AutoResetEvent $STOP_NAME

if ($Stop) {
    $stopEvent.Set() | Out-Null
    Write-Log 'Stop requested.'
    Write-Host 'Stop signalled.'
    return
}

# WPF needs a single-threaded apartment. -Sta is the default for powershell.exe,
# but pwsh and some hosts default to MTA, where ShowDialog throws.
if ([System.Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') {
    throw 'This script must run in an STA thread. Relaunch powershell.exe with -Sta.'
}

# Targets -----------------------------------------------------
# trigger.exe parses this same file for its cold-launch fallback, so the format
# stays deliberately dumb: "name = path", # for comments.
function Get-Target([string]$path) {
    if (-not (Test-Path $path)) { throw "targets.txt not found at $path." }

    $found = [System.Collections.Generic.List[PSCustomObject]]::new()
    foreach ($line in Get-Content $path) {
        $trimmed = $line.Trim()
        if (-not $trimmed -or $trimmed.StartsWith('#')) { continue }

        $eq = $trimmed.IndexOf('=')
        if ($eq -lt 1) {
            Write-Log "Ignoring malformed targets.txt line: $trimmed"
            continue
        }

        $name       = $trimmed.Substring(0, $eq).Trim()
        $scriptPath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine(
            $PSScriptRoot, [Environment]::ExpandEnvironmentVariables($trimmed.Substring($eq + 1).Trim())))

        if (-not (Test-Path $scriptPath)) {
            Write-Log "Target '$name' skipped, script not found: $scriptPath"
            continue
        }
        $found.Add([PSCustomObject]@{ Name = $name; Script = $scriptPath })
    }
    return $found
}

$targets = Get-Target (Join-Path $PSScriptRoot 'targets.txt')
if ($targets.Count -eq 0) { throw 'No usable targets in targets.txt.' }

# Any existing instance owns the show events, so ask it to stand down before we
# claim the mutex. Launching this script always replaces the running host.
$mutex = [System.Threading.Mutex]::new($false, $MUTEX_NAME)
$stopEvent.Set() | Out-Null
if (-not $mutex.WaitOne(5000)) {
    throw "Another instance is still holding $MUTEX_NAME and did not exit within 5s."
}
# Clear our own stand-down signal so the wait loop does not exit immediately.
$stopEvent.Reset() | Out-Null

foreach ($t in $targets) {
    $ev = New-AutoResetEvent ($SHOW_NAME_PREFIX + $t.Name)
    $ev.Reset() | Out-Null
    $t | Add-Member -NotePropertyName Event -NotePropertyValue $ev
}

# Preload -----------------------------------------------------
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore

$dll = Join-Path $PSScriptRoot 'lib\Win32Focus.dll'
if (Test-Path $dll) {
    Add-Type -Path $dll
} else {
    Write-Log 'lib\Win32Focus.dll missing, compiling from source. Run build.ps1.'
    Add-Type -Path (Join-Path $PSScriptRoot 'src\Win32Focus.cs')
}

# Loading the WPF assemblies is not enough: the first window on a thread also
# pays for theme dictionaries, the font cache and the render thread, which is
# most of a second. Show a throwaway offscreen window so no press eats that.
function Initialize-Wpf {
    $probe = [System.Windows.Window]::new()
    $probe.Width         = 1
    $probe.Height        = 1
    $probe.Left          = -32000
    $probe.Top           = -32000
    $probe.WindowStyle   = 'None'
    $probe.ShowInTaskbar = $false
    $probe.ShowActivated = $false
    $probe.Show()
    $probe.Dispatcher.Invoke([action]{}, 'ApplicationIdle') | Out-Null
    $probe.Close()
}

try {
    Initialize-Wpf
} catch {
    Write-Log "WPF prewarm failed, first press will be slower: $($_.Exception.Message)"
}

# Build each real window once, offscreen, so XAML parsing and template
# instantiation are already JITed when the first press lands. Target scripts read
# $HotkeyHostPrewarm from this scope and show themselves offscreen instead of
# calling ShowDialog.
$HotkeyHostPrewarm = $true
foreach ($t in $targets) {
    try {
        & $t.Script
    } catch {
        Write-Log "Prewarm of '$($t.Name)' failed, first press will be slower: $($_.Exception.Message)"
    }
}
$HotkeyHostPrewarm = $false

# Wait loop ---------------------------------------------------
# Index 0 is the stop event; the rest line up with $targets in order.
$handles = [System.Collections.Generic.List[IntPtr]]::new()
$handles.Add($stopEvent.SafeWaitHandle.DangerousGetHandle())
foreach ($t in $targets) { $handles.Add($t.Event.SafeWaitHandle.DangerousGetHandle()) }
$handleArray = $handles.ToArray()

Write-Log "Host started, serving: $(($targets | ForEach-Object { $_.Name }) -join ', ')"

try {
    while ($true) {
        $i = [HotkeyHost]::Wait($handleArray)
        if ($i -eq [HotkeyHost]::WAIT_STOP) { break }

        $target = $targets[$i - 1]
        try {
            & $target.Script
        } catch {
            # A broken target script must not kill the host; the next press picks
            # up the fixed file.
            Write-Log "Target '$($target.Name)' failed: $($_.Exception.Message)"
        }
    }
    Write-Log 'Stop signal received, exiting.'
} finally {
    $mutex.ReleaseMutex()
    $mutex.Dispose()
    foreach ($t in $targets) { $t.Event.Dispose() }
    $stopEvent.Dispose()
}
