#!/usr/bin/env python3
"""Script selector — filter and launch a script from the mac scripts dir.

Mac counterpart of windows/script-selector.ps1 in ~/Documents/scripts. Bound to
alt+shift+p in mac/hammerspoon/init.lua.
"""
import os
import subprocess
import sys
import tkinter as tk
import tkinter.font as tkfont
from pathlib import Path

SCRIPTS_DIR = Path.home() / "Documents" / "scripts" / "mac"
WEZTERM = "/Applications/WezTerm.app/Contents/MacOS/wezterm"

EXTENSIONS = {".sh", ".py"}
EXCLUDE_NAMES = {
    "config.sh",
    "config.example.sh",
}

# Monokai
BG = "#272822"
PANEL = "#1E1F1C"
FG = "#F8F8F2"
BORDER = "#49483E"
BORDER_LIGHT = "#75715E"
ACCENT = "#A6E22E"
ACCENT_HOVER = "#B9EF5C"
RED = "#F92672"
RED_HOVER = "#FF5C93"


class RoundedButton(tk.Canvas):
    """Canvas button — Aqua Tk ignores bg/fg on tk.Button and can't round corners."""

    def __init__(self, parent, text, command, bg, hover_bg, fg, radius=6, padx=14, pady=6):
        font = tkfont.Font(family="Helvetica", size=12, weight="bold")
        w = font.measure(text) + padx * 2
        h = font.metrics("linespace") + pady * 2
        super().__init__(
            parent, width=w, height=h, bg=BG, highlightthickness=0, bd=0, cursor="pointinghand"
        )
        self.bg, self.hover_bg = bg, hover_bg
        self.shapes = self._draw_round_rect(w, h, radius, bg)
        self.create_text(w / 2, h / 2, text=text, fill=fg, font=font)

        self.bind("<Button-1>", lambda _e: command())
        self.bind("<Enter>", lambda _e: self._recolor(hover_bg))
        self.bind("<Leave>", lambda _e: self._recolor(bg))

    def _draw_round_rect(self, w, h, r, fill):
        d = r * 2
        ids = [
            self.create_rectangle(r, 0, w - r, h, fill=fill, outline=fill),
            self.create_rectangle(0, r, w, h - r, fill=fill, outline=fill),
            self.create_oval(0, 0, d, d, fill=fill, outline=fill),
            self.create_oval(w - d, 0, w, d, fill=fill, outline=fill),
            self.create_oval(0, h - d, d, h, fill=fill, outline=fill),
            self.create_oval(w - d, h - d, w, h, fill=fill, outline=fill),
        ]
        return ids

    def _recolor(self, color):
        for i in self.shapes:
            self.itemconfig(i, fill=color, outline=color)


def selectable_scripts():
    files = [
        p
        for p in SCRIPTS_DIR.iterdir()
        if p.is_file() and p.suffix in EXTENSIONS and p.name not in EXCLUDE_NAMES
    ]
    # Hide a .py when a same-stem .sh wrapper exists (e.g. create_prs_gui.py).
    shell_stems = {p.stem for p in files if p.suffix == ".sh"}
    names = [p.name for p in files if not (p.suffix == ".py" and p.stem in shell_stems)]
    return sorted(names, key=str.casefold)


def _lua_str(value):
    return "'" + value.replace("\\", "\\\\").replace("'", "\\'") + "'"


def _osascript(script, detach=False):
    subprocess.Popen(
        ["osascript", "-e", script],
        start_new_session=detach,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def activate_pid(pid, wait=0.0, tries=40, delay=0.25):
    """Bring the process with this pid to the front once it has a window.

    Detached, so it outlives the selector. Never activate by bundle id
    ("org.python.python"): that targets Python.app rather than a process, and
    AppleScript launches it if it is not running — which relaunches whatever
    script it last had open (e.g. the Workspace Launcher).
    """
    # `exit repeat` inside a `try` raises, and the `try` then swallows it, so the
    # loop would never activate anything. Flag it and break outside the `try`.
    script = f"""
    delay {wait}
    tell application "System Events"
        set done to false
        repeat {tries} times
            try
                set p to first process whose unix id is {pid}
                if (count of windows of p) > 0 then
                    set frontmost of p to true
                    set done to true
                end if
            end try
            if done then exit repeat
            delay {delay}
        end repeat
    end tell
    """
    _osascript(script, detach=True)


def is_gui_script(path):
    """True for scripts that open their own window — no terminal needed."""
    if "_gui" in path.stem:
        return True
    try:
        return "tkinter" in path.read_text(errors="ignore")
    except OSError:
        return False


def run_script(name):
    path = SCRIPTS_DIR / name

    if is_gui_script(path):
        argv = [sys.executable, str(path)] if path.suffix == ".py" else ["/bin/bash", str(path)]
        proc = subprocess.Popen(argv, cwd=str(SCRIPTS_DIR), start_new_session=True)
        # The .sh wrappers `exec` python, so the pid stays valid across the swap.
        # wait: let the selector quit first so the child wins the front spot.
        activate_pid(proc.pid, wait=1.0)
        return

    if path.suffix == ".py":
        inner = f'{sys.executable} "{path}"'
    else:
        # bash, not zsh: these scripts use ${BASH_SOURCE[0]} to find their dir.
        inner = f'/bin/bash "{path}"'
    # Keep an interactive shell open after the script exits, like -NoExit / cmd /k.
    inner = f"{inner}; echo; exec /bin/zsh -i"

    if Path(WEZTERM).exists():
        # Pass the command via default_prog, not positional args: the user's
        # gui-startup hook treats `wezterm start -- <cmd>` as a workspace spawn
        # request and opens a multi-tab session.
        prog = ",".join(_lua_str(a) for a in ("/bin/zsh", "-ic", inner))
        cmd = [
            WEZTERM,
            "--config",
            f"default_prog={{{prog}}}",
            "--config",
            f"default_cwd={_lua_str(str(SCRIPTS_DIR))}",
            "start",
            "--always-new-process",
        ]
        subprocess.Popen(cmd, start_new_session=True)
        _osascript('delay 1\ntell application "WezTerm" to activate', detach=True)
    else:
        script = inner.replace("\\", "\\\\").replace('"', '\\"')
        subprocess.Popen(
            [
                "osascript",
                "-e",
                f'tell application "Terminal" to do script "cd {SCRIPTS_DIR}; {script}"',
                "-e",
                'tell application "Terminal" to activate',
            ]
        )


class SelectorApp:
    def __init__(self, root):
        self.root = root
        self.scripts = selectable_scripts()

        root.title("Script Selector")
        root.geometry("420x480")
        root.configure(bg=BG)

        outer = tk.Frame(root, bg=BG, padx=8, pady=8)
        outer.pack(fill="both", expand=True)

        self.filter_var = tk.StringVar()
        self.filter_entry = tk.Entry(
            outer,
            textvariable=self.filter_var,
            bg=PANEL,
            fg=FG,
            insertbackground=FG,
            selectbackground=BORDER,
            selectforeground=FG,
            relief="flat",
            highlightthickness=1,
            highlightbackground=BORDER,
            highlightcolor=BORDER_LIGHT,
        )
        self.filter_entry.pack(fill="x", pady=(0, 6), ipady=3)
        self.filter_var.trace_add("write", lambda *_: self.refresh())

        list_frame = tk.Frame(outer, bg=BG)
        list_frame.pack(fill="both", expand=True)

        sb = tk.Scrollbar(list_frame)
        sb.pack(side="right", fill="y")

        self.listbox = tk.Listbox(
            list_frame,
            yscrollcommand=sb.set,
            selectmode="single",
            activestyle="none",
            font=("Menlo", 12),
            bg=PANEL,
            fg=FG,
            selectbackground=BORDER,
            selectforeground=FG,
            highlightthickness=1,
            highlightbackground=BORDER,
            relief="flat",
            borderwidth=0,
        )
        self.listbox.pack(side="left", fill="both", expand=True)
        sb.config(command=self.listbox.yview)

        btn_frame = tk.Frame(outer, bg=BG)
        btn_frame.pack(fill="x", pady=(8, 0))

        RoundedButton(btn_frame, "Run", self.launch, ACCENT, ACCENT_HOVER, BG).pack(side="right")
        RoundedButton(btn_frame, "Cancel", root.destroy, RED, RED_HOVER, FG).pack(
            side="right", padx=(0, 8)
        )

        self.listbox.bind("<Double-Button-1>", lambda _e: self.launch())
        self.listbox.bind("<Return>", lambda _e: self.launch())
        self.filter_entry.bind("<Return>", lambda _e: self.launch())
        self.filter_entry.bind("<Down>", self.focus_list)
        root.bind("<Escape>", lambda _e: root.destroy())

        self.refresh()
        self.filter_entry.focus_set()

    def refresh(self):
        needle = self.filter_var.get().strip().casefold()
        self.listbox.delete(0, "end")
        for name in self.scripts:
            if not needle or needle in name.casefold():
                self.listbox.insert("end", name)
        if self.listbox.size():
            self.listbox.selection_set(0)

    def focus_list(self, _event):
        if self.listbox.size():
            self.listbox.focus_set()
            self.listbox.selection_clear(0, "end")
            self.listbox.selection_set(0)
            self.listbox.activate(0)
        return "break"

    def launch(self):
        sel = self.listbox.curselection()
        if not sel:
            return
        run_script(self.listbox.get(sel[0]))
        self.root.destroy()


if __name__ == "__main__":
    root = tk.Tk()
    app = SelectorApp(root)
    root.lift()
    root.attributes("-topmost", True)
    root.after(200, lambda: root.attributes("-topmost", False))
    root.focus_force()
    # Hammerspoon activates us by pid too; this covers a direct launch.
    root.after(10, lambda: activate_pid(os.getpid(), tries=12, delay=0.15))
    root.after(60, lambda: app.filter_entry.focus_force())
    root.mainloop()
