#!/usr/bin/env python3
import tkinter as tk
from tkinter import ttk
import json
import subprocess
from pathlib import Path

RECENT_FILE = Path.home() / ".workspace_launcher_recent.json"
DOCS_DIR = Path.home() / "Documents"
WEZTERM = "/Applications/WezTerm.app/Contents/MacOS/wezterm"

PORT_DEFAULTS = {"webdev": "8080", "npm": "5173"}


def load_recent():
    if RECENT_FILE.exists():
        try:
            with open(RECENT_FILE) as f:
                data = json.load(f)
            # Filter out old-format string entries
            return [r for r in data if isinstance(r, dict)]
        except Exception:
            pass
    return []


def save_recent(workspace, inner_cmd):
    recent = load_recent()
    # Remove any existing entry for this workspace
    recent = [r for r in recent if r["workspace"] != workspace]
    recent.insert(0, {"workspace": workspace, "cmd": inner_cmd})
    with open(RECENT_FILE, "w") as f:
        json.dump(recent[:30], f)


def run_cmd(workspace, inner_cmd):
    cmd = [WEZTERM, "start", "--always-new-process", workspace, inner_cmd]
    log_path = Path.home() / "launcher_debug.log"
    with open(log_path, "w") as log:
        log.write("ARGS:\n" + "\n".join(f"  [{i}] {a}" for i, a in enumerate(cmd)) + "\n\n")
        subprocess.Popen(cmd, stdout=log, stderr=log)
    subprocess.Popen(["bash", "-c", 'sleep 1 && osascript -e \'tell application "WezTerm" to activate\''])


class LauncherApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Workspace Launcher")
        self.root.geometry("420x540")
        self.root.resizable(True, True)

        self._setup_styles()
        self._build_ui()

    def _setup_styles(self):
        style = ttk.Style()
        style.configure("TNotebook.Tab", padding=[12, 6])
        style.configure("Dimmed.TButton", foreground="gray")
        style.map("Dimmed.TButton", foreground=[("disabled", "gray")])

    def _build_ui(self):
        self.notebook = ttk.Notebook(self.root)
        self.notebook.pack(fill="both", expand=True, padx=12, pady=12)

        self.recent_frame = ttk.Frame(self.notebook, padding=8)
        self.ws_frame = ttk.Frame(self.notebook, padding=8)

        self.notebook.add(self.recent_frame, text="Recent")
        self.notebook.add(self.ws_frame, text="Workspaces")
        self.notebook.select(self.recent_frame)

        self._build_recent_tab()
        self._build_workspaces_tab()

    # ── Recent tab ──────────────────────────────────────────────────────────

    def _build_recent_tab(self):
        ttk.Label(self.recent_frame, text="Recently launched workspaces").pack(anchor="w", pady=(0, 4))

        list_frame = ttk.Frame(self.recent_frame)
        list_frame.pack(fill="both", expand=True)

        sb = ttk.Scrollbar(list_frame)
        sb.pack(side="right", fill="y")

        self.recent_listbox = tk.Listbox(
            list_frame,
            yscrollcommand=sb.set,
            selectmode="single",
            activestyle="dotbox",
            font=("Menlo", 13),
        )
        self.recent_listbox.pack(side="left", fill="both", expand=True)
        sb.config(command=self.recent_listbox.yview)

        btn_frame = ttk.Frame(self.recent_frame)
        btn_frame.pack(fill="x", pady=(10, 2), padx=6)

        self.remove_btn = ttk.Button(btn_frame, text="Remove", command=self._remove_recent, state="disabled", style="Dimmed.TButton")
        self.remove_btn.pack(side="left")
        ttk.Button(btn_frame, text="Launch", command=self._launch_recent).pack(side="right")

        self.recent_listbox.bind("<<ListboxSelect>>", self._on_recent_select)

        self._refresh_recent_list()

    def _refresh_recent_list(self):
        self.recent_listbox.delete(0, "end")
        for entry in load_recent():
            label = f"{entry['workspace']}  —  {entry['cmd']}"
            self.recent_listbox.insert("end", label)

    def _launch_recent(self):
        sel = self.recent_listbox.curselection()
        if not sel:
            self._show_error("Select a recent entry first.")
            return
        entry = load_recent()[sel[0]]
        try:
            run_cmd(entry["workspace"], entry["cmd"])
        except Exception as e:
            self._show_error(str(e))
            return
        self.root.destroy()

    def _on_recent_select(self, _event):
        if self.recent_listbox.curselection():
            self.remove_btn.config(state="normal", style="TButton")
        else:
            self.remove_btn.config(state="disabled", style="Dimmed.TButton")

    def _remove_recent(self):
        sel = self.recent_listbox.curselection()
        if not sel:
            self._show_error("Select an entry to remove.")
            return
        recent = load_recent()
        del recent[sel[0]]
        with open(RECENT_FILE, "w") as f:
            json.dump(recent, f)
        self._refresh_recent_list()
        self.remove_btn.config(state="disabled", style="Dimmed.TButton")

    # ── Workspaces tab ───────────────────────────────────────────────────────

    def _build_workspaces_tab(self):
        frame = self.ws_frame

        ttk.Label(frame, text="Select workspace").pack(anchor="w", pady=(0, 4))

        list_frame = ttk.Frame(frame)
        list_frame.pack(fill="both", expand=True)

        sb = ttk.Scrollbar(list_frame)
        sb.pack(side="right", fill="y")

        self.ws_listbox = tk.Listbox(
            list_frame,
            yscrollcommand=sb.set,
            selectmode="single",
            activestyle="dotbox",
            font=("Menlo", 13),
        )
        self.ws_listbox.pack(side="left", fill="both", expand=True)
        sb.config(command=self.ws_listbox.yview)

        if DOCS_DIR.exists():
            for d in sorted((p.name for p in DOCS_DIR.iterdir() if p.is_dir()), key=str.casefold):
                self.ws_listbox.insert("end", d)

        # ── Mode radio row ──
        radio_frame = ttk.Frame(frame)
        radio_frame.pack(fill="x", pady=(10, 0))

        self.run_mode = tk.StringVar(value="webdev")

        ttk.Radiobutton(
            radio_frame,
            text="webdev",
            variable=self.run_mode,
            value="webdev",
            command=self._on_mode_change,
        ).pack(side="left")

        ttk.Radiobutton(
            radio_frame,
            text="npm run",
            variable=self.run_mode,
            value="npm",
            command=self._on_mode_change,
        ).pack(side="left", padx=(12, 0))

        self.dummy_var = tk.BooleanVar(value=False)
        self.dummy_cb = ttk.Checkbutton(radio_frame, text="dummy", variable=self.dummy_var)

        # ── Port row ──
        port_frame = ttk.Frame(frame)
        port_frame.pack(fill="x", pady=(8, 0))

        ttk.Label(port_frame, text="Port:").pack(side="left")

        self.port_var = tk.StringVar(value=PORT_DEFAULTS["webdev"])
        ttk.Entry(port_frame, textvariable=self.port_var, width=8).pack(side="left", padx=(6, 0))

        # ── Launch button ──
        ttk.Button(frame, text="Launch", command=self._launch).pack(pady=(14, 2))

    def _on_mode_change(self):
        mode = self.run_mode.get()
        if mode == "npm":
            self.dummy_cb.pack(side="left", padx=(12, 0))
            self.port_var.set(PORT_DEFAULTS["npm"])
        else:
            self.dummy_cb.pack_forget()
            self.dummy_var.set(False)
            self.port_var.set(PORT_DEFAULTS["webdev"])

    def _launch(self):
        sel = self.ws_listbox.curselection()
        if not sel:
            self._show_error("Select a workspace first.")
            return

        workspace = self.ws_listbox.get(sel[0])
        port = self.port_var.get().strip()
        mode = self.run_mode.get()

        if mode == "npm":
            script = "dev-dummy" if self.dummy_var.get() else "dev"
            inner_cmd = f"npm run {script} -- --port={port}"
        else:
            inner_cmd = f"webdev serve web:{port}"

        try:
            run_cmd(workspace, inner_cmd)
        except Exception as e:
            self._show_error(str(e))
            return

        save_recent(workspace, inner_cmd)
        self.root.destroy()

    def _show_error(self, msg):
        win = tk.Toplevel(self.root)
        win.title("Notice")
        win.resizable(False, False)
        ttk.Label(win, text=msg, padding=20).pack()
        ttk.Button(win, text="OK", command=win.destroy).pack(pady=(0, 10))
        win.grab_set()
        win.focus_set()


if __name__ == "__main__":
    root = tk.Tk()
    LauncherApp(root)
    root.lift()
    root.attributes("-topmost", True)
    root.after(200, lambda: root.attributes("-topmost", False))
    root.bind("<Escape>", lambda e: root.destroy())
    root.focus_force()
    root.mainloop()
