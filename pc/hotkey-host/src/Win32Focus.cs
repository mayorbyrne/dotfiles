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
    [DllImport("dwmapi.dll")] public static extern int DwmSetWindowAttribute(IntPtr hWnd, int attr, ref int value, int size);
}

// Wakeup channel for the resident GUI host (hotkey.ps1).
//
// Win+Shift+R and Win+Shift+P cannot be claimed with RegisterHotKey: Windows 11
// reserves combinations like these, so the call fails with
// ERROR_HOTKEY_ALREADY_REGISTERED. PowerToys Keyboard Manager can still
// intercept them via its low-level keyboard hook, so KBM runs trigger.exe, which
// signals the per-target Show event this class waits on.
public static class HotkeyHost {
    public const string StopEventName      = "HotkeyHost.Stop";
    public const string ShowEventPrefix    = "HotkeyHost.Show.";
    public const string SingletonMutexName = "HotkeyHost.Singleton";

    // Index 0 of the handle array is the stop event by convention, so a return
    // of 0 means shut down and anything higher identifies a target.
    public const int WAIT_STOP = 0;

    private const uint PM_REMOVE   = 0x0001;
    private const uint QS_ALLINPUT = 0x04FF;
    private const uint INFINITE    = 0xFFFFFFFF;
    private const uint WAIT_OBJECT_0 = 0;
    private const uint WAIT_FAILED   = 0xFFFFFFFF;

    [StructLayout(LayoutKind.Sequential)]
    private struct MSG {
        public IntPtr hwnd;
        public uint   message;
        public IntPtr wParam;
        public IntPtr lParam;
        public uint   time;
        public int    ptX;
        public int    ptY;
    }

    [DllImport("user32.dll")]
    private static extern bool PeekMessage(out MSG lpMsg, IntPtr hWnd, uint min, uint max, uint remove);

    [DllImport("user32.dll")]
    private static extern bool TranslateMessage(ref MSG lpMsg);

    [DllImport("user32.dll")]
    private static extern IntPtr DispatchMessage(ref MSG lpMsg);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern uint MsgWaitForMultipleObjects(
        uint nCount, IntPtr[] pHandles, bool bWaitAll, uint dwMilliseconds, uint dwWakeMask);

    // Blocks until one of the handles is signalled and returns its index. Window
    // messages are dispatched while waiting so any WPF windows left on this
    // thread stay responsive between presses.
    public static int Wait(IntPtr[] handles) {
        if (handles == null || handles.Length == 0) {
            throw new ArgumentException("At least the stop handle is required.", "handles");
        }
        // MsgWaitForMultipleObjects reserves one slot for the message signal.
        if (handles.Length > 63) {
            throw new ArgumentException("At most 63 handles are supported.", "handles");
        }
        uint count = (uint)handles.Length;
        while (true) {
            uint r = MsgWaitForMultipleObjects(count, handles, false, INFINITE, QS_ALLINPUT);
            if (r == WAIT_FAILED) {
                throw new InvalidOperationException(
                    "MsgWaitForMultipleObjects failed: " + Marshal.GetLastWin32Error());
            }
            if (r >= WAIT_OBJECT_0 && r < WAIT_OBJECT_0 + count) {
                return (int)(r - WAIT_OBJECT_0);
            }
            // r == WAIT_OBJECT_0 + count: messages are pending, not a handle.
            MSG msg;
            while (PeekMessage(out msg, IntPtr.Zero, 0, 0, PM_REMOVE)) {
                TranslateMessage(ref msg);
                DispatchMessage(ref msg);
            }
        }
    }
}
