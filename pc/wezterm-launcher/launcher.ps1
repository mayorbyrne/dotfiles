Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName System.Windows.Forms

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32Focus {
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, IntPtr pid);
    [DllImport("user32.dll")] public static extern uint GetCurrentThreadId();
    [DllImport("user32.dll")] public static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);
    [DllImport("user32.dll")] public static extern IntPtr SetFocus(IntPtr hWnd);
}
"@

$historyFile = "$env:APPDATA\wezterm-launcher\history.json"
$configFile  = "$env:APPDATA\wezterm-launcher\config.json"
$script:projectsRoot = $null

function Get-LauncherConfig {
    if (-not (Test-Path $script:configFile)) { return $null }
    try {
        return Get-Content $script:configFile -Raw | ConvertFrom-Json
    } catch {
        return $null
    }
}

function Save-LauncherConfig([string]$projectsRoot) {
    $dir = Split-Path $script:configFile
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [pscustomobject]@{ projectsRoot = $projectsRoot } | ConvertTo-Json | Set-Content $script:configFile -Encoding UTF8
}

function Get-WeztermLuaPath {
    $candidate = Join-Path $env:USERPROFILE ".wezterm.lua"
    if (-not (Test-Path $candidate)) { return $null }
    try {
        $item = Get-Item $candidate -Force
        if ($item.LinkType -and $item.Target) {
            $target = $item.Target
            if ($target -is [array]) { $target = $target[0] }
            if ($target -and (Test-Path $target)) { return [string]$target }
        }
    } catch {}
    return $candidate
}

function Update-WeztermProjectsRoot([string]$projectsRoot) {
    $luaPath = Get-WeztermLuaPath
    if (-not $luaPath) {
        [System.Windows.MessageBox]::Show(
            "Could not find ~/.wezterm.lua to update the projects path.",
            "Wezterm Launcher",
            "OK",
            "Warning"
        ) | Out-Null
        return
    }

    $luaRoot = ($projectsRoot -replace '\\', '/')
    $content = Get-Content $luaPath -Raw
    $pattern = '(?ms)(-- wezterm-launcher:projects-root\s*\r?\n\s*if wezterm\.target_triple == "x86_64-pc-windows-msvc" then\r?\n\s*projects_root = ")[^"]*(")'
    if ($content -match $pattern) {
        $updated = [regex]::Replace($content, $pattern, "`${1}$luaRoot`${2}")
    } else {
        # Fallback: replace any Windows projects_root assignment
        $fallback = '(?m)(if wezterm\.target_triple == "x86_64-pc-windows-msvc" then\r?\n\s*projects_root = ")[^"]*(")'
        if ($content -notmatch $fallback) {
            [System.Windows.MessageBox]::Show(
                "Could not find the Windows projects_root setting in .wezterm.lua.",
                "Wezterm Launcher",
                "OK",
                "Warning"
            ) | Out-Null
            return
        }
        $updated = [regex]::Replace($content, $fallback, "`${1}$luaRoot`${2}")
    }

    Set-Content -Path $luaPath -Value $updated -Encoding UTF8
}

function Ensure-ProjectsRoot {
    $config = Get-LauncherConfig
    if ($config -and $config.projectsRoot -and (Test-Path $config.projectsRoot)) {
        $script:projectsRoot = [string]$config.projectsRoot
        return $true
    }

    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = "Choose the folder where your projects live (e.g. D:\git or Documents)"
    $dialog.ShowNewFolderButton = $true
    if ($config -and $config.projectsRoot) {
        $dialog.SelectedPath = [string]$config.projectsRoot
    } elseif (Test-Path "D:\git") {
        $dialog.SelectedPath = "D:\git"
    } elseif (Test-Path (Join-Path $env:USERPROFILE "Documents")) {
        $dialog.SelectedPath = Join-Path $env:USERPROFILE "Documents"
    }

    $result = $dialog.ShowDialog()
    if ($result -ne [System.Windows.Forms.DialogResult]::OK -or [string]::IsNullOrWhiteSpace($dialog.SelectedPath)) {
        return $false
    }

    $script:projectsRoot = $dialog.SelectedPath.TrimEnd('\')
    Save-LauncherConfig -projectsRoot $script:projectsRoot
    Update-WeztermProjectsRoot -projectsRoot $script:projectsRoot
    return $true
}

function Get-AppHistory {
    if (-not (Test-Path $script:historyFile)) { return [System.Collections.Generic.List[PSCustomObject]]::new() }
    try {
        $items = Get-Content $script:historyFile -Raw | ConvertFrom-Json
        $list  = [System.Collections.Generic.List[PSCustomObject]]::new()
        foreach ($item in $items) {
            $list.Add([PSCustomObject]@{ Name = $item.Name; Command = $item.Command })
        }
        return $list
    } catch {
        return [System.Collections.Generic.List[PSCustomObject]]::new()
    }
}

function Save-AppHistory([System.Collections.Generic.List[PSCustomObject]]$history) {
    $dir = Split-Path $script:historyFile
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
    @($history | Select-Object -First 50) | ConvertTo-Json -Depth 2 | Set-Content $script:historyFile -Encoding UTF8
}

function Remove-AppHistory([string]$name) {
    $existing   = Get-AppHistory
    $newHistory = [System.Collections.Generic.List[PSCustomObject]]::new()
    foreach ($item in $existing) {
        if ($item.Name -ne $name) { $newHistory.Add($item) }
    }
    Save-AppHistory $newHistory
}

function Prepend-AppHistory([string]$name, [string]$command) {
    $existing   = Get-AppHistory
    $newHistory = [System.Collections.Generic.List[PSCustomObject]]::new()
    $newHistory.Add([PSCustomObject]@{ Name = $name; Command = $command })
    foreach ($item in $existing) {
        if ($item.Name -ne $name) { $newHistory.Add($item) }
    }
    Save-AppHistory $newHistory
}

function Test-HasDevDummy([string]$folder) {
    if (-not $folder) { return $false }
    $pkgPath = Join-Path $script:projectsRoot "$folder\package.json"
    if (-not (Test-Path $pkgPath)) { return $false }
    try {
        $pkg = Get-Content $pkgPath -Raw | ConvertFrom-Json
        return $null -ne $pkg.scripts.'dev-dummy'
    } catch {
        return $false
    }
}

function Get-WeztermWorkspaces {
    $appHistory = Get-AppHistory
    $seen       = @{}
    $list       = [System.Collections.Generic.List[PSCustomObject]]::new()

    foreach ($item in $appHistory) {
        if (-not $seen.ContainsKey($item.Name)) {
            $seen[$item.Name] = $true
            $list.Add($item)
        }
    }

    try {
        $mru   = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU"
        $order = $mru.MRUList.ToCharArray()
        foreach ($key in $order) {
            $raw = $mru."$key"
            if (-not $raw) { continue }
            $cmd = $raw -replace "\\1$", ""
            if ($cmd -match '^wezterm start (\S+)\s+"(.+)"$') {
                $name = $Matches[1]; $command = $Matches[2]
                if (-not $seen.ContainsKey($name)) {
                    $seen[$name] = $true
                    $list.Add([PSCustomObject]@{ Name = $name; Command = $command })
                }
            }
        }
    } catch {}

    return [System.Collections.Generic.List[PSCustomObject]]($list | Select-Object -First 50)
}

if (-not (Ensure-ProjectsRoot)) {
    exit 0
}

$workspaces = Get-WeztermWorkspaces
$gitFolders = @()
if (Test-Path $script:projectsRoot) {
    $gitFolders = Get-ChildItem $script:projectsRoot -Directory | Select-Object -ExpandProperty Name | Sort-Object
}
[xml]$xaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Wezterm Launcher"
    Width="460" Height="530"
    WindowStartupLocation="CenterScreen"
    ResizeMode="NoResize"
    ShowInTaskbar="True"
    Topmost="True">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Padding" Value="12,5"/>
            <Setter Property="MinWidth" Value="70"/>
        </Style>
        <Style TargetType="Label">
            <Setter Property="Padding" Value="0,4,8,4"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
        </Style>
    </Window.Resources>
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <TabControl Grid.Row="0" x:Name="MainTabs" Margin="8,8,8,0">

            <!-- ── Recent ── -->
            <TabItem Header="Recent">
                <Grid Margin="6,6,6,4">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <ListBox Grid.Row="0" x:Name="RecentList" FontFamily="Consolas" FontSize="12"
                             SelectedValuePath="Content"/>
                    <StackPanel Grid.Row="1" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,4,0,0">
                        <Button x:Name="RemoveButton" Content="Remove" IsEnabled="False"/>
                    </StackPanel>
                    <TextBlock Grid.Row="2" x:Name="RecentPreview"
                               FontSize="11" Foreground="#666"
                               TextTrimming="CharacterEllipsis"
                               Margin="0,4,0,2"/>
                </Grid>
            </TabItem>

            <!-- ── New Workspace ── -->
            <TabItem Header="New Workspace">
                <Grid Margin="6,6,6,4">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>

                    <ListBox Grid.Row="0" x:Name="FolderList" FontFamily="Consolas" FontSize="12"/>

                    <StackPanel Grid.Row="1" Orientation="Horizontal" Margin="0,10,0,0">
                        <Label Content="Run with:"/>
                        <RadioButton x:Name="RadioWebdev" Content="webdev"
                                     IsChecked="True" VerticalAlignment="Center" Margin="0,0,16,0"/>
                        <RadioButton x:Name="RadioNpm" Content="npm run dev"
                                     VerticalAlignment="Center" Margin="0,0,12,0"/>
                        <CheckBox x:Name="DummyCheck" Content="dummy"
                                  VerticalAlignment="Center"
                                  Visibility="Collapsed"/>
                    </StackPanel>

                    <StackPanel Grid.Row="2" Orientation="Horizontal" Margin="0,8,0,0">
                        <Label Content="Port:"/>
                        <TextBox x:Name="PortBox" Text="8080" Width="70"
                                 VerticalContentAlignment="Center" Height="24"/>
                    </StackPanel>

                    <TextBlock Grid.Row="3" x:Name="NewPreview"
                               FontSize="11" Foreground="#666"
                               TextTrimming="CharacterEllipsis"
                               Margin="0,8,0,2"/>
                </Grid>
            </TabItem>
        </TabControl>

        <StackPanel Grid.Row="1" Orientation="Horizontal" HorizontalAlignment="Right" Margin="8">
            <Button x:Name="CancelButton" Content="Cancel" IsCancel="True" Margin="0,0,8,0"/>
            <Button x:Name="LaunchButton" Content="Launch" IsDefault="True"/>
        </StackPanel>
    </Grid>
</Window>
"@

$reader    = [System.Xml.XmlNodeReader]::new($xaml)
$window    = [System.Windows.Markup.XamlReader]::Load($reader)

$mainTabs     = $window.FindName("MainTabs")
$recentList   = $window.FindName("RecentList")
$recentPreview= $window.FindName("RecentPreview")
$removeBtn    = $window.FindName("RemoveButton")
$folderList   = $window.FindName("FolderList")
$radioWebdev  = $window.FindName("RadioWebdev")
$radioNpm     = $window.FindName("RadioNpm")
$portBox      = $window.FindName("PortBox")
$newPreview   = $window.FindName("NewPreview")
$dummyCheck   = $window.FindName("DummyCheck")
$launchBtn    = $window.FindName("LaunchButton")

# ── Recent tab ──────────────────────────────────────────────
foreach ($ws in $workspaces) {
    $lbi = [System.Windows.Controls.ListBoxItem]::new()
    $lbi.Content = $ws.Name
    if ($ws.Command -match 'dummy') {
        $lbi.Foreground = [System.Windows.Media.Brushes]::MediumPurple
    }
    $recentList.Items.Add($lbi) | Out-Null
}
if ($recentList.Items.Count -gt 0) { $recentList.SelectedIndex = 0 }

$updateRecentPreview = {
    $name = $recentList.SelectedValue
    $ws   = $workspaces | Where-Object { $_.Name -eq $name } | Select-Object -First 1
    $recentPreview.Text = if ($ws) { "cmd: $($ws.Command)" } else { "" }
    $removeBtn.IsEnabled = $null -ne $name
}
$recentList.Add_SelectionChanged($updateRecentPreview)
& $updateRecentPreview

$removeBtn.Add_Click({
    $lbi  = $recentList.SelectedItem
    $name = $recentList.SelectedValue
    if (-not $name) { return }
    Remove-AppHistory -name $name
    $toRemove = $workspaces | Where-Object { $_.Name -eq $name } | Select-Object -First 1
    if ($toRemove) { $workspaces.Remove($toRemove) | Out-Null }
    $recentList.Items.Remove($lbi)
    $recentPreview.Text = ""
    $removeBtn.IsEnabled = $false
})

# ── New Workspace tab ────────────────────────────────────────
foreach ($f in $gitFolders) { $folderList.Items.Add($f) | Out-Null }

$updateNewPreview = {
    $folder = $folderList.SelectedItem
    $port   = $portBox.Text.Trim()
    if (-not $folder) { $newPreview.Text = ""; return }
    if ($radioWebdev.IsChecked) {
        $cmd = "webdev serve web:$port"
    } elseif ($dummyCheck.IsChecked) {
        $cmd = "npm run dev-dummy ``-- --port=$port"
    } else {
        $cmd = "npm run dev ``-- --port=$port"
    }
    $newPreview.Text = "wezterm start $folder `"$cmd`""
}

$updateDummyVisibility = {
    $folder = $folderList.SelectedItem
    if ($radioNpm.IsChecked -and (Test-HasDevDummy $folder)) {
        $dummyCheck.Visibility = "Visible"
    } else {
        $dummyCheck.Visibility = "Collapsed"
        $dummyCheck.IsChecked  = $false
    }
}

$toggleDummy = {
    & $updateDummyVisibility
    $portBox.Text = if ($radioNpm.IsChecked) { "5173" } else { "8080" }
    & $updateNewPreview
}

$folderList.Add_SelectionChanged({
    & $updateDummyVisibility
    & $updateNewPreview
})
$radioWebdev.Add_Checked($toggleDummy)
$radioNpm.Add_Checked($toggleDummy)
$dummyCheck.Add_Checked($updateNewPreview)
$dummyCheck.Add_Unchecked($updateNewPreview)
$portBox.Add_TextChanged($updateNewPreview)

# ── Launch ───────────────────────────────────────────────────
$launchBtn.Add_Click({
    if ($mainTabs.SelectedIndex -eq 0) {
        $name = $recentList.SelectedValue
        if (-not $name) {
            [System.Windows.MessageBox]::Show("Please select a workspace.", "Wezterm Launcher", "OK", "Warning")
            return
        }
        $ws  = $workspaces | Where-Object { $_.Name -eq $name } | Select-Object -First 1
        $cmd = $ws.Command -replace "``", ""
        Prepend-AppHistory -name $name -command $ws.Command
        Start-Process wezterm -ArgumentList "start `"$name`" `"$cmd`""
    } else {
        $folder = $folderList.SelectedItem
        $port   = $portBox.Text.Trim()
        if (-not $folder) {
            [System.Windows.MessageBox]::Show("Please select a folder.", "Wezterm Launcher", "OK", "Warning")
            return
        }
        if ($radioWebdev.IsChecked) {
            $cmd = "webdev serve web:$port"
        } elseif ($dummyCheck.IsChecked) {
            $cmd = "npm run dev-dummy ``-- --port=$port"
        } else {
            $cmd = "npm run dev ``-- --port=$port"
        }
        Prepend-AppHistory -name $folder -command $cmd
        Start-Process wezterm -ArgumentList "start `"$folder`" `"$cmd`""
    }
    $window.Close()
})

$window.Add_Loaded({
    $hwnd = (New-Object System.Windows.Interop.WindowInteropHelper($window)).Handle
    $fgHwnd = [Win32Focus]::GetForegroundWindow()
    $fgThread = [Win32Focus]::GetWindowThreadProcessId($fgHwnd, [IntPtr]::Zero)
    $myThread = [Win32Focus]::GetCurrentThreadId()
    [Win32Focus]::AttachThreadInput($fgThread, $myThread, $true)
    [Win32Focus]::BringWindowToTop($hwnd)
    [Win32Focus]::SetForegroundWindow($hwnd)
    [Win32Focus]::AttachThreadInput($fgThread, $myThread, $false)
    $window.Activate()
})

$window.ShowDialog() | Out-Null
