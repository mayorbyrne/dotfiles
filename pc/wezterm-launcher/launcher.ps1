Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName System.Windows.Forms

# hotkey.ps1 preloads Win32Focus from its prebuilt DLL, and reruns this script
# on every press, so skip the ~350ms C# compile when the type already exists.
if (-not ('Win32Focus' -as [type])) {
    Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    public class Win32Focus {
        [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
        [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr hWnd);
        [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
        [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, IntPtr pid);
        [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId();
        [DllImport("user32.dll")] public static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);
        [DllImport("user32.dll")] public static extern IntPtr SetFocus(IntPtr hWnd);
    }
"@
}

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

function Update-WeztermProjectsRoot([string]$projectsRoot) {
    # WezTerm reads the projects root from this file so the tracked
    # .wezterm.lua stays free of machine-specific paths.
    $dir = Join-Path $env:USERPROFILE ".config\wezterm"
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $luaRoot = $projectsRoot.Replace('\', '/')
    # WriteAllText with a BOM-less encoding: Windows PowerShell's -Encoding UTF8
    # prepends a BOM, which WezTerm would read as part of the path.
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    $path = Join-Path $dir "projects_root.txt"
    $content = "$luaRoot`n"
    if ([System.IO.File]::Exists($path) -and [System.IO.File]::ReadAllText($path) -eq $content) { return }
    [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
}

function Ensure-ProjectsRoot {
    $config = Get-LauncherConfig
    if ($config -and $config.projectsRoot -and (Test-Path $config.projectsRoot)) {
        $script:projectsRoot = [string]$config.projectsRoot
        Update-WeztermProjectsRoot -projectsRoot $script:projectsRoot
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

function Normalize-AgentCwd([string]$cwd) {
    if (-not $cwd) { return "" }
    return ($cwd -replace '\\', '/').TrimEnd('/').ToLowerInvariant()
}

function Get-AgentStateMap {
    $path = Join-Path $env:USERPROFILE ".config\wezterm\agent_state.txt"
    $map = @{}
    if (-not (Test-Path $path)) { return $map }
    $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    foreach ($line in Get-Content $path) {
        if ($line -match '^\s*#' -or [string]::IsNullOrWhiteSpace($line)) { continue }
        $parts = $line.Split('|')
        if ($parts.Count -lt 3) { continue }
        $updated = 0
        if ($parts.Count -ge 4) { [void][int64]::TryParse($parts[3], [ref]$updated) }
        if ($updated -gt 0 -and $updated -lt ($now - 21600)) { continue }
        $cwd = Normalize-AgentCwd $parts[1]
        if (-not $map.ContainsKey($cwd)) {
            $map[$cwd] = [System.Collections.Generic.List[PSCustomObject]]::new()
        }
        $map[$cwd].Add([PSCustomObject]@{ Agent = $parts[0]; Status = $parts[2] })
    }
    return $map
}

function Get-AgentsForFolder([string]$folder, $agentMap) {
    if (-not $folder -or -not $agentMap) { return @() }
    $cwd = Normalize-AgentCwd (Join-Path $script:projectsRoot $folder)
    if ($agentMap.ContainsKey($cwd)) { return @($agentMap[$cwd]) }
    $suffix = "/" + $folder.ToLowerInvariant()
    foreach ($key in $agentMap.Keys) {
        if ($key.EndsWith($suffix)) { return @($agentMap[$key]) }
    }
    return @()
}

function Format-AgentPreview($agents) {
    if (-not $agents -or $agents.Count -eq 0) { return "" }
    return ($agents | ForEach-Object { "$($_.Agent) $($_.Status)" }) -join "  "
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

function Start-Workspace([string]$name, [string]$cmd, [bool]$claudeChrome) {
    $wezArgs = "start `"$name`" `"$cmd`""
    # .wezterm.lua reads this as args[3]; kept out of history so it never sticks.
    if ($claudeChrome) { $wezArgs += " claude-chrome" }
    Start-Process wezterm -ArgumentList $wezArgs
}

# exit would take down hotkey.ps1, which runs this script in its own process.
if (-not (Ensure-ProjectsRoot)) {
    return
}

$workspaces = [System.Collections.Generic.List[PSCustomObject]]::new()
$agentMap = @{}
[xml]$xaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Wezterm Launcher"
    Width="460" Height="530"
    WindowStartupLocation="CenterScreen"
    ResizeMode="NoResize"
    ShowInTaskbar="True"
    Topmost="True"
    Background="#272822"
    Foreground="#F8F8F2">
    <Window.Resources>

        <!-- Monokai palette -->
        <SolidColorBrush x:Key="MkBg"        Color="#272822"/>
        <SolidColorBrush x:Key="MkBgDark"    Color="#1E1F1C"/>
        <SolidColorBrush x:Key="MkBgHover"   Color="#3E3D32"/>
        <SolidColorBrush x:Key="MkSelection" Color="#49483E"/>
        <SolidColorBrush x:Key="MkFg"        Color="#F8F8F2"/>
        <SolidColorBrush x:Key="MkComment"   Color="#75715E"/>
        <SolidColorBrush x:Key="MkGreen"     Color="#A6E22E"/>
        <SolidColorBrush x:Key="MkBlue"      Color="#66D9EF"/>
        <SolidColorBrush x:Key="MkOrange"    Color="#FD971F"/>
        <SolidColorBrush x:Key="MkPurple"    Color="#AE81FF"/>
        <SolidColorBrush x:Key="MkRed"       Color="#F92672"/>
        <SolidColorBrush x:Key="MkBorder"    Color="#49483E"/>

        <Style TargetType="Label">
            <Setter Property="Padding"     Value="0,4,8,4"/>
            <Setter Property="FontWeight"  Value="SemiBold"/>
            <Setter Property="Foreground"  Value="#66D9EF"/>
        </Style>

        <Style TargetType="TextBox">
            <Setter Property="Background"            Value="#1E1F1C"/>
            <Setter Property="Foreground"            Value="#F8F8F2"/>
            <Setter Property="BorderBrush"           Value="#49483E"/>
            <Setter Property="BorderThickness"       Value="1"/>
            <Setter Property="CaretBrush"            Value="#F8F8F2"/>
            <Setter Property="SelectionBrush"        Value="#49483E"/>
            <Setter Property="Padding"               Value="4,2"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
        </Style>

        <Style TargetType="RadioButton">
            <Setter Property="Foreground"            Value="#F8F8F2"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
        </Style>

        <Style TargetType="CheckBox">
            <Setter Property="Foreground"            Value="#F8F8F2"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
        </Style>

        <Style TargetType="ListBox">
            <Setter Property="Background"      Value="#1E1F1C"/>
            <Setter Property="BorderBrush"     Value="#49483E"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Foreground"      Value="#F8F8F2"/>
            <Setter Property="Padding"         Value="0"/>
            <Setter Property="ScrollViewer.HorizontalScrollBarVisibility" Value="Disabled"/>
        </Style>

        <Style TargetType="ListBoxItem">
            <Setter Property="Foreground"  Value="#F8F8F2"/>
            <Setter Property="Background"  Value="Transparent"/>
            <Setter Property="Padding"     Value="8,4"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ListBoxItem">
                        <Border x:Name="Bd"
                                Background="{TemplateBinding Background}"
                                Padding="{TemplateBinding Padding}">
                            <ContentPresenter TextElement.Foreground="{TemplateBinding Foreground}"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="#3E3D32"/>
                            </Trigger>
                            <MultiTrigger>
                                <MultiTrigger.Conditions>
                                    <Condition Property="IsSelected"   Value="True"/>
                                    <Condition Property="IsMouseOver"  Value="False"/>
                                </MultiTrigger.Conditions>
                                <Setter TargetName="Bd" Property="Background" Value="#49483E"/>
                            </MultiTrigger>
                            <MultiTrigger>
                                <MultiTrigger.Conditions>
                                    <Condition Property="IsSelected"  Value="True"/>
                                    <Condition Property="IsMouseOver" Value="True"/>
                                </MultiTrigger.Conditions>
                                <Setter TargetName="Bd" Property="Background" Value="#49483E"/>
                            </MultiTrigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="TabControl">
            <Setter Property="Background"      Value="#272822"/>
            <Setter Property="BorderBrush"     Value="#49483E"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding"         Value="0"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="TabControl">
                        <Grid>
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="*"/>
                            </Grid.RowDefinitions>
                            <TabPanel Grid.Row="0" IsItemsHost="True"
                                      Background="#1E1F1C"/>
                            <Border Grid.Row="1"
                                    Background="{TemplateBinding Background}"
                                    BorderBrush="{TemplateBinding BorderBrush}"
                                    BorderThickness="1,0,1,1">
                                <ContentPresenter ContentSource="SelectedContent"/>
                            </Border>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="TabItem">
            <Setter Property="Background"  Value="#1E1F1C"/>
            <Setter Property="Foreground"  Value="#75715E"/>
            <Setter Property="BorderBrush" Value="#49483E"/>
            <Setter Property="Padding"     Value="14,6"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="TabItem">
                        <Border x:Name="TabBd"
                                Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="1,1,1,0"
                                Margin="0,0,2,0"
                                Padding="{TemplateBinding Padding}">
                            <ContentPresenter ContentSource="Header"
                                              TextElement.Foreground="{TemplateBinding Foreground}"
                                              TextElement.FontWeight="SemiBold"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsSelected" Value="True">
                                <Setter TargetName="TabBd" Property="Background" Value="#272822"/>
                                <Setter Property="Foreground" Value="#A6E22E"/>
                            </Trigger>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="TabBd" Property="Background" Value="#3E3D32"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Variants override BtnHoverBg / BtnPressedBg in Style.Resources instead of copying the template. -->
        <Style x:Key="DefaultButton" TargetType="Button">
            <Style.Resources>
                <SolidColorBrush x:Key="BtnHoverBg"   Color="#75715E"/>
                <SolidColorBrush x:Key="BtnPressedBg" Color="#3E3D32"/>
            </Style.Resources>
            <Setter Property="Padding"          Value="12,5"/>
            <Setter Property="MinWidth"         Value="70"/>
            <Setter Property="Background"       Value="#49483E"/>
            <Setter Property="Foreground"       Value="#F8F8F2"/>
            <Setter Property="BorderBrush"      Value="#75715E"/>
            <Setter Property="BorderThickness"  Value="1"/>
            <Setter Property="Cursor"           Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="Bd"
                                Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                CornerRadius="3"
                                Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"
                                              TextElement.Foreground="{TemplateBinding Foreground}"
                                              TextElement.FontWeight="{TemplateBinding FontWeight}"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="{DynamicResource BtnHoverBg}"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="{DynamicResource BtnPressedBg}"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter Property="Opacity" Value="0.35"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="Button" BasedOn="{StaticResource DefaultButton}"/>

        <Style x:Key="LaunchButtonStyle" TargetType="Button" BasedOn="{StaticResource DefaultButton}">
            <Style.Resources>
                <SolidColorBrush x:Key="BtnHoverBg"   Color="#C4E857"/>
                <SolidColorBrush x:Key="BtnPressedBg" Color="#8AB825"/>
            </Style.Resources>
            <Setter Property="Background"       Value="#A6E22E"/>
            <Setter Property="Foreground"       Value="#272822"/>
            <Setter Property="BorderBrush"      Value="#A6E22E"/>
            <Setter Property="FontWeight"       Value="SemiBold"/>
        </Style>

    </Window.Resources>
    <Grid Background="#272822">
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
                             SelectionMode="Extended"
                             SelectedValuePath="Content"/>
                    <StackPanel Grid.Row="1" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,4,0,0">
                        <Button x:Name="RemoveButton" Content="Remove" IsEnabled="False"/>
                    </StackPanel>
                    <TextBlock Grid.Row="2" x:Name="RecentPreview"
                               FontSize="11" Foreground="#75715E"
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

                    <ListBox Grid.Row="0" x:Name="FolderList" FontFamily="Consolas" FontSize="12"
                             SelectionMode="Extended"/>

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
                        <TextBox x:Name="PortBox" Text="8080" Width="70" Height="24"/>
                    </StackPanel>

                    <TextBlock Grid.Row="3" x:Name="NewPreview"
                               FontSize="11" Foreground="#75715E"
                               TextTrimming="CharacterEllipsis"
                               Margin="0,8,0,2"/>
                </Grid>
            </TabItem>
        </TabControl>

        <StackPanel Grid.Row="1" Orientation="Horizontal" HorizontalAlignment="Right" Margin="8">
            <CheckBox x:Name="ChromeCheck" Content="claude --chrome"
                      VerticalAlignment="Center" Margin="0,0,16,0"/>
            <Button x:Name="CancelButton" Content="Cancel" IsCancel="True" Margin="0,0,8,0"/>
            <Button x:Name="LaunchButton" Content="Launch" IsDefault="True" Style="{StaticResource LaunchButtonStyle}"/>
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
$chromeCheck  = $window.FindName("ChromeCheck")
$launchBtn    = $window.FindName("LaunchButton")

$updateRecentPreview = {
    $count = $recentList.SelectedItems.Count
    if ($count -eq 1) {
        $name = $recentList.SelectedValue
        $ws   = $workspaces | Where-Object { $_.Name -eq $name } | Select-Object -First 1
        $preview = if ($ws) { "cmd: $($ws.Command)" } else { "" }
        $agentText = Format-AgentPreview (Get-AgentsForFolder $name $agentMap)
        if ($agentText) { $preview = "$preview | $agentText" }
        $recentPreview.Text = $preview
    } elseif ($count -gt 1) {
        $recentPreview.Text = "$count workspaces selected"
    } else {
        $recentPreview.Text = ""
    }
    $removeBtn.IsEnabled = $count -gt 0
}
$recentList.Add_SelectionChanged($updateRecentPreview)

$removeBtn.Add_Click({
    $selected = @($recentList.SelectedItems)
    if ($selected.Count -eq 0) { return }
    foreach ($lbi in $selected) {
        $name = $lbi.Content
        Remove-AppHistory -name $name
        $toRemove = $workspaces | Where-Object { $_.Name -eq $name } | Select-Object -First 1
        if ($toRemove) { $workspaces.Remove($toRemove) | Out-Null }
        $recentList.Items.Remove($lbi)
    }
    $recentPreview.Text = ""
    $removeBtn.IsEnabled = $false
})

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
        $selected = @($recentList.SelectedItems)
        if ($selected.Count -eq 0) {
            [System.Windows.MessageBox]::Show("Please select a workspace.", "Wezterm Launcher", "OK", "Warning")
            return
        }
        foreach ($lbi in $selected) {
            $name = $lbi.Content
            $ws   = $workspaces | Where-Object { $_.Name -eq $name } | Select-Object -First 1
            $cmd  = $ws.Command -replace "``", ""
            Prepend-AppHistory -name $name -command $ws.Command
            Start-Workspace -name $name -cmd $cmd -claudeChrome $chromeCheck.IsChecked
        }
    } else {
        $selectedFolders = @($folderList.SelectedItems)
        $port = $portBox.Text.Trim()
        if ($selectedFolders.Count -eq 0) {
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
        foreach ($folder in $selectedFolders) {
            Prepend-AppHistory -name $folder -command $cmd
            Start-Workspace -name $folder -cmd $cmd -claudeChrome $chromeCheck.IsChecked
        }
    }
    $window.Close()
})

$window.Add_Loaded({
    if ($HotkeyHostPrewarm) { return }
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

$window.Add_ContentRendered({
    $script:workspaces = Get-WeztermWorkspaces
    $script:agentMap = Get-AgentStateMap

    foreach ($ws in $workspaces) {
        $lbi = [System.Windows.Controls.ListBoxItem]::new()
        $lbi.Content = $ws.Name
        $agents = Get-AgentsForFolder $ws.Name $agentMap
        if ($agents | Where-Object { $_.Status -eq 'working' }) {
            $lbi.Foreground = $window.FindResource('MkOrange')
        } elseif ($agents | Where-Object { $_.Status -eq 'error' }) {
            $lbi.Foreground = $window.FindResource('MkRed')
        } elseif ($ws.Command -match 'dummy') {
            $lbi.Foreground = $window.FindResource('MkPurple')
        } elseif ($agents.Count -gt 0) {
            $lbi.Foreground = $window.FindResource('MkBlue')
        }
        $recentList.Items.Add($lbi) | Out-Null
    }
    if ($recentList.Items.Count -gt 0) { $recentList.SelectedIndex = 0 }
    & $updateRecentPreview

    foreach ($path in [System.IO.Directory]::EnumerateDirectories($script:projectsRoot)) {
        $folderList.Items.Add([System.IO.Path]::GetFileName($path)) | Out-Null
    }
    $folderList.Items.SortDescriptions.Add([System.ComponentModel.SortDescription]::new('', [System.ComponentModel.ListSortDirection]::Ascending))
})

# hotkey.ps1 sets $HotkeyHostPrewarm at startup to build the window once
# offscreen, moving XAML parsing and JIT off the first real press.
if ($HotkeyHostPrewarm) {
    $window.WindowStartupLocation = 'Manual'
    $window.Left          = -32000
    $window.Top           = -32000
    $window.Topmost       = $false
    $window.ShowActivated = $false
    $window.ShowInTaskbar = $false
    $window.Show()
    $window.Dispatcher.Invoke([action]{}, 'ApplicationIdle') | Out-Null
    $window.Close()
    return
}

$window.ShowDialog() | Out-Null
