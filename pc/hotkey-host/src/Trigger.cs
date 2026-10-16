using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Threading;

// Wakes the resident GUI host (hotkey.ps1) as fast as Windows can start a
// process. Bound through PowerToys Keyboard Manager, which is the only thing
// able to intercept combinations the shell has reserved.
//
// Usage: trigger.exe [target]     target defaults to "launcher"
//
// Built as a winexe so no console window flashes on press.
public static class Trigger {
    private const string ShowEventPrefix = "HotkeyHost.Show.";
    private const string DefaultTarget   = "launcher";

    public static int Main(string[] args) {
        string target = (args.Length > 0 && args[0].Length > 0) ? args[0] : DefaultTarget;

        try {
            EventWaitHandle show = EventWaitHandle.OpenExisting(ShowEventPrefix + target);
            show.Set();
            return 0;
        } catch (WaitHandleCannotBeOpenedException) {
            // No host running, or it does not serve this target. Fall back to a
            // cold launch so the hotkey still works, just at the old ~1.7s.
            return ColdLaunch(target);
        }
    }

    private static int ColdLaunch(string target) {
        string script;
        if (!TryResolveTarget(target, out script)) { return 1; }

        ProcessStartInfo psi = new ProcessStartInfo(
            "powershell.exe",
            "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Sta -File \"" + script + "\"");
        psi.UseShellExecute = false;
        psi.CreateNoWindow  = true;
        Process.Start(psi);
        return 0;
    }

    // targets.txt sits next to hotkey.ps1, one directory up from lib\.
    private static bool TryResolveTarget(string target, out string script) {
        script = null;

        string libDir = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);
        string root   = Path.GetDirectoryName(libDir);
        string config = Path.Combine(root, "targets.txt");
        if (!File.Exists(config)) { return false; }

        foreach (string line in File.ReadAllLines(config)) {
            string trimmed = line.Trim();
            if (trimmed.Length == 0 || trimmed.StartsWith("#")) { continue; }

            int eq = trimmed.IndexOf('=');
            if (eq < 1) { continue; }

            string name = trimmed.Substring(0, eq).Trim();
            if (!name.Equals(target, StringComparison.OrdinalIgnoreCase)) { continue; }

            // Same resolution as hotkey.ps1: %VARS% expanded, relative to root.
            string path = Path.GetFullPath(Path.Combine(
                root, Environment.ExpandEnvironmentVariables(trimmed.Substring(eq + 1).Trim())));

            if (!File.Exists(path)) { return false; }
            script = path;
            return true;
        }
        return false;
    }
}
