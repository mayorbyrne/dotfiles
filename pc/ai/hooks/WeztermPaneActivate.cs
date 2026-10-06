using System;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.Runtime.InteropServices.ComTypes;
using System.Text;
using System.Text.RegularExpressions;
using Microsoft.Win32;
using Windows.Data.Xml.Dom;
using Windows.UI.Notifications;

[ComVisible(true)]
[Guid(WeztermPaneActivate.ToastClsid)]
[ClassInterface(ClassInterfaceType.None)]
public class NotificationActivator : INotificationActivationCallback
{
    public void Activate(string appUserModelId, string invokedArgs, NOTIFICATION_USER_INPUT_DATA[] data, uint count)
    {
        WeztermPaneActivate.Log("com-activate " + invokedArgs);
        WeztermPaneActivate.ActivateFromArg(invokedArgs);
        WeztermPaneActivate.PostQuitMessage(0);
    }
}

[ComImport]
[Guid("53E31837-6600-4A81-9395-75CFFE746F94")]
[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface INotificationActivationCallback
{
    void Activate(
        [MarshalAs(UnmanagedType.LPWStr)] string appUserModelId,
        [MarshalAs(UnmanagedType.LPWStr)] string invokedArgs,
        [MarshalAs(UnmanagedType.LPArray, SizeParamIndex = 3)] NOTIFICATION_USER_INPUT_DATA[] data,
        uint count);
}

[ComImport]
[Guid("00021401-0000-0000-C000-000000000046")]
public class CShellLink
{
}

[StructLayout(LayoutKind.Sequential)]
public struct NOTIFICATION_USER_INPUT_DATA
{
    [MarshalAs(UnmanagedType.LPWStr)]
    public string Key;

    [MarshalAs(UnmanagedType.LPWStr)]
    public string Value;
}

internal static class WeztermPaneActivate
{
    internal const string Aumid = "Kevin.WezTerm.Agent";
    internal const string ToastClsid = "a3e8c8e2-7b1f-4d3a-9c4e-2f6b8d1a0e11";
    private const string ToastActivatedArg = "-ToastActivated";
    private const int CLSCTX_LOCAL_SERVER = 4;
    private const int REGCLS_MULTIPLEUSE = 1;
    private const int CLASS_E_NOAGGREGATION = -2147221232;
    private const int E_NOINTERFACE = -2147467262;
    private const int S_OK = 0;
    private const int WM_TIMER = 0x0113;
    private static readonly Guid IUnknownGuid = new Guid("00000000-0000-0000-C000-000000000046");
    private static readonly Guid CallbackIid = new Guid("53E31837-6600-4A81-9395-75CFFE746F94");

    [STAThread]
    private static int Main(string[] args)
    {
        try
        {
            SetCurrentProcessExplicitAppUserModelID(Aumid);

            if (HasArg(args, "--register"))
            {
                Register();
                return 0;
            }

            if (HasArg(args, "--notify"))
            {
                ShowToast(
                    GetOption(args, "--title") ?? "agent finished",
                    GetOption(args, "--message") ?? "Click to return to the agent tab",
                    GetOption(args, "--pane") ?? "0");
                return 0;
            }

            if (HasArg(args, ToastActivatedArg) || HasArg(args, "-Embedding"))
            {
                WaitForComActivation();
                if (File.Exists(PendingPath()))
                {
                    Log("com-fallback-pending");
                    ActivateFromArg("");
                }
                return 0;
            }

            string joined = args.Length > 0 ? string.Join(" ", args) : "";
            ActivateFromArg(joined);
            return 0;
        }
        catch (Exception ex)
        {
            Log("fatal " + ex);
            return 1;
        }
    }

    internal static void ActivateFromArg(string raw)
    {
        string paneId = ParsePaneId(raw);
        if (string.IsNullOrEmpty(paneId))
        {
            paneId = ReadPendingPane();
        }

        ClearPendingPane();
        if (!string.IsNullOrEmpty(paneId))
        {
            WriteActivateRequest(paneId);
        }
        FocusWeztermGui();
        if (!string.IsNullOrEmpty(paneId))
        {
            RunWeztermCli("cli --no-auto-start activate-pane --pane-id " + paneId);
        }
    }

    private static void RunWeztermCli(string arguments)
    {
        string wezterm = FindWezterm();
        if (string.IsNullOrEmpty(wezterm))
        {
            Log("activate-miss wezterm");
            return;
        }

        try
        {
            string powershell = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.System),
                @"WindowsPowerShell\v1.0\powershell.exe");
            var info = new ProcessStartInfo
            {
                FileName = File.Exists(powershell) ? powershell : "powershell.exe",
                Arguments = "-NoProfile -WindowStyle Hidden -Command \"& '" + wezterm.Replace("'", "''") + "' " + arguments + "\"",
                UseShellExecute = false,
                CreateNoWindow = true,
                WorkingDirectory = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile),
            };
            using (Process p = Process.Start(info))
            {
                if (p == null)
                {
                    Log("activate-start-null");
                    return;
                }

                p.WaitForExit(5000);
                Log("activate-pane exit=" + p.ExitCode);
            }
        }
        catch (Exception ex)
        {
            Log("activate-error " + ex.Message);
        }
    }

    private static void FocusWeztermGui()
    {
        IntPtr hwnd = FindWeztermHwnd();
        if (hwnd == IntPtr.Zero)
        {
            Log("focus-miss hwnd");
            return;
        }

        if (IsIconic(hwnd))
        {
            ShowWindow(hwnd, SW_RESTORE);
        }
        else
        {
            ShowWindow(hwnd, SW_SHOW);
        }

        uint targetPid;
        uint targetThread = GetWindowThreadProcessId(hwnd, out targetPid);
        if (targetPid != 0)
        {
            AllowSetForegroundWindow(unchecked((int)targetPid));
        }
        AllowSetForegroundWindow(-1);
        uint unused;
        uint fgThread = GetWindowThreadProcessId(GetForegroundWindow(), out unused);
        uint selfThread = GetCurrentThreadId();
        AttachThreadInput(selfThread, fgThread, true);
        AttachThreadInput(selfThread, targetThread, true);
        BringWindowToTop(hwnd);
        SetWindowPos(hwnd, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_SHOWWINDOW);
        SetWindowPos(hwnd, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_SHOWWINDOW);
        bool focused = SetForegroundWindow(hwnd);
        SetActiveWindow(hwnd);
        SetFocus(hwnd);
        IntPtr child = GetWindow(hwnd, GW_CHILD);
        if (child != IntPtr.Zero)
        {
            SetFocus(child);
        }
        if (GetForegroundWindow() != hwnd)
        {
            keybd_event(VK_MENU, 0, 0, UIntPtr.Zero);
            focused = SetForegroundWindow(hwnd);
            SetActiveWindow(hwnd);
            SetFocus(child != IntPtr.Zero ? child : hwnd);
            keybd_event(VK_MENU, 0, KEYEVENTF_KEYUP, UIntPtr.Zero);
        }

        ClickWindow(hwnd);
        AttachThreadInput(selfThread, fgThread, false);
        AttachThreadInput(selfThread, targetThread, false);
        Log("focus hwnd=" + hwnd + " child=" + child + " ok=" + focused + " fg=" + (GetForegroundWindow() == hwnd));
    }

    private static IntPtr FindWeztermHwnd()
    {
        foreach (Process process in Process.GetProcessesByName("wezterm-gui"))
        {
            try
            {
                if (process.MainWindowHandle != IntPtr.Zero)
                {
                    return process.MainWindowHandle;
                }

                IntPtr found = IntPtr.Zero;
                uint pid = (uint)process.Id;
                EnumWindows(delegate(IntPtr hwnd, IntPtr lParam)
                {
                    if (!IsWindowVisible(hwnd))
                    {
                        return true;
                    }

                    uint windowPid;
                    GetWindowThreadProcessId(hwnd, out windowPid);
                    if (windowPid == pid)
                    {
                        found = hwnd;
                        return false;
                    }

                    return true;
                }, IntPtr.Zero);

                if (found != IntPtr.Zero)
                {
                    return found;
                }
            }
            catch
            {
            }
            finally
            {
                process.Dispose();
            }
        }

        return IntPtr.Zero;
    }

    private static void ClickWindow(IntPtr hwnd)
    {
        RECT client;
        if (!GetClientRect(hwnd, out client))
        {
            return;
        }

        POINT target = new POINT();
        target.X = Math.Max(8, (client.Right - client.Left) / 2);
        target.Y = Math.Max(8, (client.Bottom - client.Top) * 2 / 3);
        if (!ClientToScreen(hwnd, ref target))
        {
            return;
        }

        POINT saved;
        GetCursorPos(out saved);
        int vx = GetSystemMetrics(SM_XVIRTUALSCREEN);
        int vy = GetSystemMetrics(SM_YVIRTUALSCREEN);
        int vw = Math.Max(1, GetSystemMetrics(SM_CXVIRTUALSCREEN) - 1);
        int vh = Math.Max(1, GetSystemMetrics(SM_CYVIRTUALSCREEN) - 1);
        int absX = (int)(((long)(target.X - vx) * 65535) / vw);
        int absY = (int)(((long)(target.Y - vy) * 65535) / vh);

        INPUT[] inputs = new INPUT[3];
        inputs[0] = MouseInput(absX, absY, MOUSEEVENTF_MOVE | MOUSEEVENTF_ABSOLUTE | MOUSEEVENTF_VIRTUALDESK);
        inputs[1] = MouseInput(absX, absY, MOUSEEVENTF_LEFTDOWN | MOUSEEVENTF_ABSOLUTE | MOUSEEVENTF_VIRTUALDESK);
        inputs[2] = MouseInput(absX, absY, MOUSEEVENTF_LEFTUP | MOUSEEVENTF_ABSOLUTE | MOUSEEVENTF_VIRTUALDESK);
        SendInput((uint)inputs.Length, inputs, Marshal.SizeOf(typeof(INPUT)));
        SetCursorPos(saved.X, saved.Y);
        Log("focus-click " + target.X + "," + target.Y);
    }

    private static INPUT MouseInput(int absX, int absY, uint flags)
    {
        INPUT input = new INPUT();
        input.type = INPUT_MOUSE;
        input.mi.dx = absX;
        input.mi.dy = absY;
        input.mi.dwFlags = flags;
        return input;
    }

    private static void ShowToast(string title, string message, string paneId)
    {
        WritePendingPane(paneId);
        string launch = "wezterm-pane:" + (string.IsNullOrEmpty(paneId) ? "0" : paneId);
        string xml =
            "<toast launch=\"" + Xml(launch) + "\" duration=\"long\">" +
            "<visual><binding template=\"ToastGeneric\">" +
            "<text>" + Xml(title) + "</text>" +
            "</binding></visual>" +
            "</toast>";

        var doc = new XmlDocument();
        doc.LoadXml(xml);
        try
        {
            ToastNotificationManager.History.Remove("finished", "agent", Aumid);
        }
        catch
        {
        }

        var toast = new ToastNotification(doc);
        toast.Tag = "finished";
        toast.Group = "agent";
        ToastNotificationManager.CreateToastNotifier(Aumid).Show(toast);
        Log("notify " + launch);
    }

    private static void WaitForComActivation()
    {
        var factory = new NotificationActivatorClassFactory();
        uint cookie;
        int hr = CoRegisterClassObject(new Guid(ToastClsid), factory, CLSCTX_LOCAL_SERVER, REGCLS_MULTIPLEUSE, out cookie);
        Log("com-listen hr=" + hr);
        SetTimer(IntPtr.Zero, UIntPtr.Zero, 15000, IntPtr.Zero);

        MSG msg;
        while (GetMessage(out msg, IntPtr.Zero, 0, 0) > 0)
        {
            if (msg.message == WM_TIMER)
            {
                Log("com-timeout");
                break;
            }
            TranslateMessage(ref msg);
            DispatchMessage(ref msg);
        }

        GC.KeepAlive(factory);
    }

    private static void Register()
    {
        string exe = Process.GetCurrentProcess().MainModule.FileName;
        string wezterm = FindWezterm();

        using (RegistryKey key = Registry.CurrentUser.CreateSubKey(@"Software\Classes\wezterm-pane"))
        {
            key.SetValue("", "URL:wezterm-pane");
            key.SetValue("URL Protocol", "");
            key.SetValue("EditFlags", 0x00210000, RegistryValueKind.DWord);
        }
        using (RegistryKey cmd = Registry.CurrentUser.CreateSubKey(@"Software\Classes\wezterm-pane\shell\open\command"))
        {
            cmd.SetValue("", "\"" + exe + "\" \"%1\"");
        }
        using (RegistryKey app = Registry.CurrentUser.CreateSubKey(@"Software\Classes\AppUserModelId\" + Aumid))
        {
            app.SetValue("DisplayName", "WezTerm Agent");
            app.SetValue("CustomActivator", "{" + ToastClsid + "}");
            if (!string.IsNullOrEmpty(wezterm))
            {
                app.SetValue("IconUri", wezterm);
            }
        }
        using (RegistryKey clsid = Registry.CurrentUser.CreateSubKey(@"Software\Classes\CLSID\{" + ToastClsid + "}"))
        {
            clsid.SetValue("", "WezTerm Agent Toast Activator");
        }
        using (RegistryKey server = Registry.CurrentUser.CreateSubKey(@"Software\Classes\CLSID\{" + ToastClsid + @"}\LocalServer32"))
        {
            server.SetValue("", "\"" + exe + "\" " + ToastActivatedArg);
        }

        string startDir = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
            @"Microsoft\Windows\Start Menu\Programs");
        Directory.CreateDirectory(startDir);
        string shortcut = Path.Combine(startDir, "WezTerm Agent.lnk");
        try
        {
            CreateShortcut(shortcut, exe, wezterm);
            StampShortcut(shortcut);
        }
        catch (Exception ex)
        {
            Log("shortcut " + ex.GetType().Name + " " + ex.Message);
        }
        Log("register " + exe);
    }

    private static void CreateShortcut(string shortcutPath, string targetPath, string iconPath)
    {
        var link = (IShellLinkW)new CShellLink();
        link.SetPath(targetPath);
        link.SetDescription("Open the finished WezTerm agent tab");
        if (!string.IsNullOrEmpty(iconPath) && File.Exists(iconPath))
        {
            link.SetIconLocation(iconPath, 0);
        }

        StampStore(link, "shell-link");
        ((IPersistFile)link).Save(shortcutPath, true);
    }

    private static void StampShortcut(string shortcutPath)
    {
        Guid iid = typeof(IPropertyStore).GUID;
        IPropertyStore store;
        int hr = SHGetPropertyStoreFromParsingName(shortcutPath, IntPtr.Zero, 2, ref iid, out store);
        if (hr != 0 || store == null)
        {
            Log("shortcut-parse hr=0x" + hr.ToString("X8"));
            return;
        }

        StampStore(store, "parse");
        Marshal.ReleaseComObject(store);
    }

    private static void StampStore(object source, string via)
    {
        try
        {
            IPropertyStore store = source as IPropertyStore;
            if (store == null)
            {
                IntPtr unk = Marshal.GetIUnknownForObject(source);
                Guid iid = typeof(IPropertyStore).GUID;
                IntPtr ptr;
                int hr = Marshal.QueryInterface(unk, ref iid, out ptr);
                Marshal.Release(unk);
                if (hr != 0 || ptr == IntPtr.Zero)
                {
                    Log("shortcut-stamp " + via + " qi=0x" + hr.ToString("X8"));
                    return;
                }

                store = (IPropertyStore)Marshal.GetObjectForIUnknown(ptr);
                Marshal.Release(ptr);
            }

            SetString(store, PkeyAppUserModelId, Aumid);
            SetGuid(store, PkeyToastActivatorClsid, new Guid(ToastClsid));
            store.Commit();
            Log("shortcut-stamp " + via + " ok");
        }
        catch (Exception ex)
        {
            Log("shortcut-stamp " + via + " " + ex.GetType().Name + " " + ex.Message);
        }
    }

    private static string FindWezterm()
    {
        string[] candidates =
        {
            Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), "WezTerm", "wezterm.exe"),
            Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86), "WezTerm", "wezterm.exe"),
        };
        foreach (string path in candidates)
        {
            if (File.Exists(path))
            {
                return path;
            }
        }

        return FindOnPath("wezterm.exe");
    }

    private static string FindOnPath(string file)
    {
        string path = Environment.GetEnvironmentVariable("PATH") ?? "";
        foreach (string dir in path.Split(Path.PathSeparator))
        {
            if (string.IsNullOrWhiteSpace(dir))
            {
                continue;
            }
            string full = Path.Combine(dir.Trim(), file);
            if (File.Exists(full))
            {
                return full;
            }
        }

        return "";
    }

    private static string ParsePaneId(string raw)
    {
        if (string.IsNullOrWhiteSpace(raw))
        {
            return "";
        }

        Match match = Regex.Match(raw, @"(\d+)");
        return match.Success ? match.Groups[1].Value : "";
    }

    private static string StateDir()
    {
        return Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), @".config\wezterm");
    }

    private static string PendingPath()
    {
        return Path.Combine(StateDir(), "pending_idle_pane.txt");
    }

    private static void WritePendingPane(string paneId)
    {
        try
        {
            Directory.CreateDirectory(StateDir());
            File.WriteAllText(PendingPath(), paneId ?? "");
        }
        catch
        {
        }
    }

    private static void WriteActivateRequest(string paneId)
    {
        try
        {
            Directory.CreateDirectory(StateDir());
            File.WriteAllText(Path.Combine(StateDir(), "activate_request.txt"), paneId ?? "");
            Log("activate-request " + paneId);
        }
        catch (Exception ex)
        {
            Log("activate-request-error " + ex.Message);
        }
    }

    private static string ReadPendingPane()
    {
        try
        {
            string path = PendingPath();
            if (File.Exists(path))
            {
                return (File.ReadAllText(path) ?? "").Trim();
            }
        }
        catch
        {
        }

        return "";
    }

    private static void ClearPendingPane()
    {
        try
        {
            string path = PendingPath();
            if (File.Exists(path))
            {
                File.Delete(path);
            }
        }
        catch
        {
        }
    }

    internal static void Log(string message)
    {
        try
        {
            Directory.CreateDirectory(StateDir());
            File.AppendAllText(
                Path.Combine(StateDir(), "activate.log"),
                DateTime.Now.ToString("o") + " " + message + Environment.NewLine);
        }
        catch
        {
        }
    }

    private static bool HasArg(string[] args, string name)
    {
        foreach (string arg in args)
        {
            if (string.Equals(arg, name, StringComparison.OrdinalIgnoreCase))
            {
                return true;
            }
        }

        return false;
    }

    private static string GetOption(string[] args, string name)
    {
        for (int i = 0; i < args.Length - 1; i++)
        {
            if (string.Equals(args[i], name, StringComparison.OrdinalIgnoreCase))
            {
                return args[i + 1];
            }
        }

        return null;
    }

    private static string Xml(string value)
    {
        if (string.IsNullOrEmpty(value))
        {
            return "";
        }

        return value
            .Replace("&", "&amp;")
            .Replace("<", "&lt;")
            .Replace(">", "&gt;")
            .Replace("\"", "&quot;");
    }

    private static readonly PropertyKey PkeyAppUserModelId = new PropertyKey(
        new Guid("9F4C2855-9F79-4B39-A8D0-E1D42DE1D5F3"),
        5);
    private static readonly PropertyKey PkeyToastActivatorClsid = new PropertyKey(
        new Guid("9F4C2855-9F79-4B39-A8D0-E1D42DE1D5F3"),
        26);

    private static void SetString(IPropertyStore store, PropertyKey key, string value)
    {
        var variant = new PropVariant();
        variant.SetString(value);
        store.SetValue(ref key, ref variant);
        variant.Clear();
    }

    private static void SetGuid(IPropertyStore store, PropertyKey key, Guid value)
    {
        var variant = new PropVariant();
        variant.SetGuid(value);
        store.SetValue(ref key, ref variant);
        variant.Clear();
    }

    [DllImport("shell32.dll", CharSet = CharSet.Unicode)]
    private static extern int SHGetPropertyStoreFromParsingName(
        string pszPath,
        IntPtr pbc,
        int flags,
        ref Guid riid,
        out IPropertyStore ppv);

    [ComImport]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    [Guid("000214F9-0000-0000-C000-000000000046")]
    private interface IShellLinkW
    {
        void GetPath([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszFile, int cch, IntPtr pfd, int fFlags);
        void GetIDList(out IntPtr ppidl);
        void SetIDList(IntPtr pidl);
        void GetDescription([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszName, int cch);
        void SetDescription([MarshalAs(UnmanagedType.LPWStr)] string pszName);
        void GetWorkingDirectory([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszDir, int cch);
        void SetWorkingDirectory([MarshalAs(UnmanagedType.LPWStr)] string pszDir);
        void GetArguments([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszArgs, int cch);
        void SetArguments([MarshalAs(UnmanagedType.LPWStr)] string pszArgs);
        void GetHotkey(out short pwHotkey);
        void SetHotkey(short wHotkey);
        void GetShowCmd(out int piShowCmd);
        void SetShowCmd(int iShowCmd);
        void GetIconLocation([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszIconPath, int cch, out int piIcon);
        void SetIconLocation([MarshalAs(UnmanagedType.LPWStr)] string pszIconPath, int iIcon);
        void SetRelativePath([MarshalAs(UnmanagedType.LPWStr)] string pszPathRel, uint dwReserved);
        void Resolve(IntPtr hwnd, uint fFlags);
        void SetPath([MarshalAs(UnmanagedType.LPWStr)] string pszFile);
    }

    [ComImport]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    [Guid("886D8EEB-8CF2-4446-8D02-CDBAAB1BDBF2")]
    private interface IPropertyStore
    {
        void GetCount(out uint cProps);
        void GetAt(uint iProp, out PropertyKey pkey);
        void GetValue(ref PropertyKey key, out PropVariant pv);
        void SetValue(ref PropertyKey key, ref PropVariant pv);
        void Commit();
    }

    [StructLayout(LayoutKind.Sequential, Pack = 4)]
    private struct PropertyKey
    {
        public Guid fmtid;
        public uint pid;

        public PropertyKey(Guid formatId, uint propertyId)
        {
            fmtid = formatId;
            pid = propertyId;
        }
    }

    [StructLayout(LayoutKind.Explicit)]
    private struct PropVariant
    {
        [FieldOffset(0)]
        private ushort vt;
        [FieldOffset(8)]
        private IntPtr ptr;

        public void SetString(string value)
        {
            Clear();
            vt = 31;
            ptr = Marshal.StringToCoTaskMemUni(value);
        }

        public void SetGuid(Guid value)
        {
            Clear();
            vt = 72;
            ptr = Marshal.AllocCoTaskMem(16);
            Marshal.Copy(value.ToByteArray(), 0, ptr, 16);
        }

        public void Clear()
        {
            PropVariantClear(ref this);
        }
    }

    [ComImport]
    [Guid("00000001-0000-0000-C000-000000000046")]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    private interface IClassFactory
    {
        [PreserveSig]
        int CreateInstance(IntPtr pUnkOuter, ref Guid riid, out IntPtr ppvObject);

        [PreserveSig]
        int LockServer(bool fLock);
    }

    private sealed class NotificationActivatorClassFactory : IClassFactory
    {
        public int CreateInstance(IntPtr pUnkOuter, ref Guid riid, out IntPtr ppvObject)
        {
            ppvObject = IntPtr.Zero;
            if (pUnkOuter != IntPtr.Zero)
            {
                return CLASS_E_NOAGGREGATION;
            }

            if (riid != CallbackIid && riid != IUnknownGuid && riid != new Guid(ToastClsid))
            {
                return E_NOINTERFACE;
            }

            ppvObject = Marshal.GetComInterfaceForObject(new NotificationActivator(), typeof(INotificationActivationCallback));
            return S_OK;
        }

        public int LockServer(bool fLock)
        {
            return S_OK;
        }
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct MSG
    {
        public IntPtr hwnd;
        public uint message;
        public IntPtr wParam;
        public IntPtr lParam;
        public uint time;
        public int ptX;
        public int ptY;
    }

    [DllImport("shell32.dll", CharSet = CharSet.Unicode)]
    private static extern int SetCurrentProcessExplicitAppUserModelID(string AppID);

    [DllImport("ole32.dll")]
    private static extern int PropVariantClear(ref PropVariant pvar);

    [DllImport("ole32.dll")]
    private static extern int CoRegisterClassObject(
        [MarshalAs(UnmanagedType.LPStruct)] Guid rclsid,
        [MarshalAs(UnmanagedType.IUnknown)] object pUnk,
        uint dwClsContext,
        uint flags,
        out uint lpdwRegister);

    [DllImport("user32.dll")]
    private static extern int GetMessage(out MSG lpMsg, IntPtr hWnd, uint wMsgFilterMin, uint wMsgFilterMax);

    [DllImport("user32.dll")]
    private static extern bool TranslateMessage(ref MSG lpMsg);

    [DllImport("user32.dll")]
    private static extern IntPtr DispatchMessage(ref MSG lpMsg);

    [DllImport("user32.dll")]
    internal static extern void PostQuitMessage(int nExitCode);

    [DllImport("user32.dll")]
    private static extern UIntPtr SetTimer(IntPtr hWnd, UIntPtr nIDEvent, uint uElapse, IntPtr lpTimerFunc);

    private const int SW_SHOW = 5;
    private const int SW_RESTORE = 9;
    private const uint SWP_NOSIZE = 0x0001;
    private const uint SWP_NOMOVE = 0x0002;
    private const uint SWP_SHOWWINDOW = 0x0040;
    private const byte VK_MENU = 0x12;
    private const uint KEYEVENTF_KEYUP = 2;
    private static readonly IntPtr HWND_TOPMOST = new IntPtr(-1);
    private static readonly IntPtr HWND_NOTOPMOST = new IntPtr(-2);

    private delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    [DllImport("user32.dll")]
    private static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);

    [DllImport("user32.dll")]
    private static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll")]
    private static extern bool IsIconic(IntPtr hWnd);

    [DllImport("user32.dll")]
    private static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll")]
    private static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    private static extern IntPtr SetActiveWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    private static extern IntPtr SetFocus(IntPtr hWnd);

    [DllImport("user32.dll")]
    private static extern IntPtr GetWindow(IntPtr hWnd, uint uCmd);

    private const uint GW_CHILD = 5;

    [DllImport("user32.dll")]
    private static extern bool BringWindowToTop(IntPtr hWnd);

    [DllImport("user32.dll")]
    private static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    private static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);

    [DllImport("kernel32.dll")]
    private static extern uint GetCurrentThreadId();

    [DllImport("user32.dll")]
    private static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);

    [DllImport("user32.dll")]
    private static extern bool AllowSetForegroundWindow(int dwProcessId);

    [DllImport("user32.dll")]
    private static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int x, int y, int cx, int cy, uint uFlags);

    [DllImport("user32.dll")]
    private static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);

    private const uint INPUT_MOUSE = 0;
    private const uint MOUSEEVENTF_MOVE = 0x0001;
    private const uint MOUSEEVENTF_LEFTDOWN = 0x0002;
    private const uint MOUSEEVENTF_LEFTUP = 0x0004;
    private const uint MOUSEEVENTF_ABSOLUTE = 0x8000;
    private const uint MOUSEEVENTF_VIRTUALDESK = 0x4000;
    private const int SM_XVIRTUALSCREEN = 76;
    private const int SM_YVIRTUALSCREEN = 77;
    private const int SM_CXVIRTUALSCREEN = 78;
    private const int SM_CYVIRTUALSCREEN = 79;

    [StructLayout(LayoutKind.Sequential)]
    private struct POINT
    {
        public int X;
        public int Y;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct RECT
    {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct MOUSEINPUT
    {
        public int dx;
        public int dy;
        public uint mouseData;
        public uint dwFlags;
        public uint time;
        public IntPtr dwExtraInfo;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct INPUT
    {
        public uint type;
        public MOUSEINPUT mi;
    }

    [DllImport("user32.dll")]
    private static extern bool GetClientRect(IntPtr hWnd, out RECT lpRect);

    [DllImport("user32.dll")]
    private static extern bool ClientToScreen(IntPtr hWnd, ref POINT lpPoint);

    [DllImport("user32.dll")]
    private static extern bool GetCursorPos(out POINT lpPoint);

    [DllImport("user32.dll")]
    private static extern bool SetCursorPos(int x, int y);

    [DllImport("user32.dll")]
    private static extern int GetSystemMetrics(int nIndex);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern uint SendInput(uint nInputs, INPUT[] pInputs, int cbSize);
}
