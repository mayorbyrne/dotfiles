#!/usr/bin/env python3
"""WezTerm workspace launcher for Linux (GTK port of pc/wezterm-launcher)."""

from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
from gi.repository import Gdk, Gtk, Pango

CONFIG_DIR = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "wezterm-launcher"
CONFIG_FILE = CONFIG_DIR / "config.json"
HISTORY_FILE = CONFIG_DIR / "history.json"
HISTORY_LIMIT = 50


def load_json(path: Path, default):
    if not path.exists():
        return default
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return default


def save_json(path: Path, data) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")


def update_wezterm_projects_root(projects_root: str) -> None:
    """WezTerm reads the projects root from this file, so the tracked
    .wezterm.lua stays free of machine-specific paths."""
    path = Path.home() / ".config" / "wezterm" / "projects_root.txt"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(projects_root.replace("\\", "/") + "\n", encoding="utf-8")


def get_projects_root() -> str | None:
    config = load_json(CONFIG_FILE, {})
    root = config.get("projectsRoot")
    if root and Path(root).is_dir():
        return str(Path(root))
    return None


def save_projects_root(projects_root: str) -> None:
    save_json(CONFIG_FILE, {"projectsRoot": projects_root})


def choose_projects_root(parent: Gtk.Window | None = None) -> str | None:
    dialog = Gtk.FileChooserDialog(
        title="Choose the folder where your projects live",
        parent=parent,
        action=Gtk.FileChooserAction.SELECT_FOLDER,
    )
    dialog.add_buttons(
        Gtk.STOCK_CANCEL,
        Gtk.ResponseType.CANCEL,
        Gtk.STOCK_OK,
        Gtk.ResponseType.OK,
    )

    existing = load_json(CONFIG_FILE, {}).get("projectsRoot")
    for candidate in (existing, str(Path.home() / "Documents"), str(Path.home() / "git"), str(Path.home())):
        if candidate and Path(candidate).is_dir():
            dialog.set_current_folder(candidate)
            break

    try:
        if dialog.run() != Gtk.ResponseType.OK:
            return None
        selected = dialog.get_filename()
        if not selected:
            return None
        return str(Path(selected))
    finally:
        dialog.destroy()


def ensure_projects_root() -> str | None:
    root = get_projects_root()
    if root:
        update_wezterm_projects_root(root)
        return root

    selected = choose_projects_root()
    if not selected:
        return None

    save_projects_root(selected)
    update_wezterm_projects_root(selected)
    return selected


def load_history() -> list[dict[str, str]]:
    items = load_json(HISTORY_FILE, [])
    history: list[dict[str, str]] = []
    if not isinstance(items, list):
        return history
    for item in items:
        if isinstance(item, dict) and item.get("Name") and item.get("Command") is not None:
            history.append({"Name": str(item["Name"]), "Command": str(item["Command"])})
    return history


def save_history(history: list[dict[str, str]]) -> None:
    save_json(HISTORY_FILE, history[:HISTORY_LIMIT])


def remove_history(name: str) -> list[dict[str, str]]:
    history = [item for item in load_history() if item["Name"] != name]
    save_history(history)
    return history


def prepend_history(name: str, command: str) -> None:
    history = [{"Name": name, "Command": command}]
    for item in load_history():
        if item["Name"] != name:
            history.append(item)
    save_history(history)


def list_project_folders(projects_root: str) -> list[str]:
    root = Path(projects_root)
    if not root.is_dir():
        return []
    return sorted(entry.name for entry in root.iterdir() if entry.is_dir() and not entry.name.startswith("."))


def has_dev_dummy(projects_root: str, folder: str | None) -> bool:
    if not folder:
        return False
    pkg_path = Path(projects_root) / folder / "package.json"
    if not pkg_path.is_file():
        return False
    try:
        pkg = json.loads(pkg_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return False
    scripts = pkg.get("scripts") or {}
    return "dev-dummy" in scripts


def build_dev_command(mode: str, port: str, dummy: bool) -> str:
    if mode == "webdev":
        return f"webdev serve web:{port}"
    if dummy:
        return f"npm run dev-dummy -- --port={port}"
    return f"npm run dev -- --port={port}"


def show_message(text: str, message_type: Gtk.MessageType = Gtk.MessageType.INFO) -> None:
    dialog = Gtk.MessageDialog(
        transient_for=None,
        flags=0,
        message_type=message_type,
        buttons=Gtk.ButtonsType.OK,
        text=text,
    )
    dialog.set_title("Wezterm Launcher")
    dialog.run()
    dialog.destroy()


def launch_wezterm(workspace: str, command: str) -> None:
    if not shutil.which("wezterm"):
        show_message("wezterm was not found on PATH.", Gtk.MessageType.ERROR)
        return
    prepend_history(workspace, command)
    subprocess.Popen(["wezterm", "start", workspace, command], start_new_session=True)


class LauncherWindow(Gtk.Window):
    def __init__(self, projects_root: str):
        super().__init__(title="Wezterm Launcher")
        self.projects_root = projects_root
        self.workspaces = load_history()
        self.set_default_size(460, 530)
        self.set_resizable(False)
        self.set_keep_above(True)
        self.set_position(Gtk.WindowPosition.CENTER)
        self.set_border_width(0)

        outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        self.add(outer)

        self.notebook = Gtk.Notebook()
        outer.pack_start(self.notebook, True, True, 0)

        self._build_recent_tab()
        self._build_new_tab()

        button_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        button_row.set_margin_top(8)
        button_row.set_margin_bottom(8)
        button_row.set_margin_start(8)
        button_row.set_margin_end(8)
        button_row.set_halign(Gtk.Align.END)
        outer.pack_start(button_row, False, False, 0)

        cancel_btn = Gtk.Button(label="Cancel")
        cancel_btn.connect("clicked", lambda *_: self.destroy())
        button_row.pack_start(cancel_btn, False, False, 0)

        launch_btn = Gtk.Button(label="Launch")
        launch_btn.get_style_context().add_class("suggested-action")
        launch_btn.connect("clicked", self.on_launch)
        button_row.pack_start(launch_btn, False, False, 0)

        self.connect("key-press-event", self.on_key_press)
        self.connect("destroy", Gtk.main_quit)

        if self.recent_store:
            self.recent_tree.set_cursor(Gtk.TreePath.new_first())
        self.update_recent_preview()
        self.update_new_preview()

    def _build_recent_tab(self) -> None:
        grid = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        grid.set_margin_top(6)
        grid.set_margin_bottom(4)
        grid.set_margin_start(6)
        grid.set_margin_end(6)

        self.recent_store = Gtk.ListStore(str, str)  # name, command
        for item in self.workspaces:
            self.recent_store.append([item["Name"], item["Command"]])

        self.recent_tree = Gtk.TreeView(model=self.recent_store)
        self.recent_tree.set_headers_visible(False)
        renderer = Gtk.CellRendererText()
        renderer.props.family = "monospace"
        column = Gtk.TreeViewColumn("Name", renderer, text=0)
        self.recent_tree.append_column(column)
        self.recent_tree.connect("cursor-changed", lambda *_: self.update_recent_preview())
        self.recent_tree.connect("row-activated", lambda *_: self.on_launch())

        scroll = Gtk.ScrolledWindow()
        scroll.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)
        scroll.set_shadow_type(Gtk.ShadowType.IN)
        scroll.add(self.recent_tree)
        grid.pack_start(scroll, True, True, 0)

        remove_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        remove_row.set_halign(Gtk.Align.END)
        self.remove_btn = Gtk.Button(label="Remove")
        self.remove_btn.set_sensitive(False)
        self.remove_btn.connect("clicked", self.on_remove)
        remove_row.pack_start(self.remove_btn, False, False, 0)
        grid.pack_start(remove_row, False, False, 0)

        self.recent_preview = Gtk.Label(xalign=0)
        self.recent_preview.set_ellipsize(Pango.EllipsizeMode.END)
        self.recent_preview.get_style_context().add_class("dim-label")
        grid.pack_start(self.recent_preview, False, False, 0)

        self.notebook.append_page(grid, Gtk.Label(label="Recent"))

    def _build_new_tab(self) -> None:
        grid = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        grid.set_margin_top(6)
        grid.set_margin_bottom(4)
        grid.set_margin_start(6)
        grid.set_margin_end(6)

        self.folder_store = Gtk.ListStore(str)
        for name in list_project_folders(self.projects_root):
            self.folder_store.append([name])

        self.folder_tree = Gtk.TreeView(model=self.folder_store)
        self.folder_tree.set_headers_visible(False)
        renderer = Gtk.CellRendererText()
        renderer.props.family = "monospace"
        self.folder_tree.append_column(Gtk.TreeViewColumn("Folder", renderer, text=0))
        self.folder_tree.connect("cursor-changed", self.on_folder_changed)
        self.folder_tree.connect("row-activated", lambda *_: self.on_launch())

        scroll = Gtk.ScrolledWindow()
        scroll.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)
        scroll.set_shadow_type(Gtk.ShadowType.IN)
        scroll.add(self.folder_tree)
        grid.pack_start(scroll, True, True, 0)

        run_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        run_label = Gtk.Label(label="Run with:")
        run_label.set_markup("<b>Run with:</b>")
        run_row.pack_start(run_label, False, False, 0)

        self.radio_webdev = Gtk.RadioButton.new_with_label_from_widget(None, "webdev")
        self.radio_npm = Gtk.RadioButton.new_with_label_from_widget(self.radio_webdev, "npm run dev")
        self.radio_webdev.set_active(True)
        self.radio_webdev.connect("toggled", self.on_mode_changed)
        self.radio_npm.connect("toggled", self.on_mode_changed)
        run_row.pack_start(self.radio_webdev, False, False, 0)
        run_row.pack_start(self.radio_npm, False, False, 0)

        self.dummy_check = Gtk.CheckButton(label="dummy")
        self.dummy_check.set_no_show_all(True)
        self.dummy_check.hide()
        self.dummy_check.connect("toggled", lambda *_: self.update_new_preview())
        run_row.pack_start(self.dummy_check, False, False, 0)
        grid.pack_start(run_row, False, False, 0)

        port_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        port_label = Gtk.Label()
        port_label.set_markup("<b>Port:</b>")
        port_row.pack_start(port_label, False, False, 0)
        self.port_entry = Gtk.Entry()
        self.port_entry.set_text("8080")
        self.port_entry.set_width_chars(8)
        self.port_entry.connect("changed", lambda *_: self.update_new_preview())
        port_row.pack_start(self.port_entry, False, False, 0)
        grid.pack_start(port_row, False, False, 0)

        self.new_preview = Gtk.Label(xalign=0)
        self.new_preview.set_ellipsize(Pango.EllipsizeMode.END)
        self.new_preview.get_style_context().add_class("dim-label")
        grid.pack_start(self.new_preview, False, False, 0)

        self.notebook.append_page(grid, Gtk.Label(label="New Workspace"))

    def selected_recent(self) -> tuple[str, str] | None:
        model, tree_iter = self.recent_tree.get_selection().get_selected()
        if tree_iter is None:
            return None
        return model[tree_iter][0], model[tree_iter][1]

    def selected_folder(self) -> str | None:
        model, tree_iter = self.folder_tree.get_selection().get_selected()
        if tree_iter is None:
            return None
        return model[tree_iter][0]

    def current_mode(self) -> str:
        return "npm" if self.radio_npm.get_active() else "webdev"

    def update_recent_preview(self) -> None:
        selected = self.selected_recent()
        self.remove_btn.set_sensitive(selected is not None)
        if selected is None:
            self.recent_preview.set_text("")
            return
        self.recent_preview.set_text(f"cmd: {selected[1]}")

    def update_dummy_visibility(self) -> None:
        folder = self.selected_folder()
        if self.radio_npm.get_active() and has_dev_dummy(self.projects_root, folder):
            self.dummy_check.show()
        else:
            self.dummy_check.set_active(False)
            self.dummy_check.hide()

    def update_new_preview(self) -> None:
        folder = self.selected_folder()
        if not folder:
            self.new_preview.set_text("")
            return
        port = self.port_entry.get_text().strip() or "8080"
        cmd = build_dev_command(self.current_mode(), port, self.dummy_check.get_active())
        self.new_preview.set_text(f'wezterm start {folder} "{cmd}"')

    def on_folder_changed(self, *_args) -> None:
        self.update_dummy_visibility()
        self.update_new_preview()

    def on_mode_changed(self, button: Gtk.RadioButton) -> None:
        if not button.get_active():
            return
        self.port_entry.set_text("5173" if self.radio_npm.get_active() else "8080")
        self.update_dummy_visibility()
        self.update_new_preview()

    def on_remove(self, *_args) -> None:
        selected = self.selected_recent()
        if selected is None:
            return
        name, _command = selected
        self.workspaces = remove_history(name)
        model, tree_iter = self.recent_tree.get_selection().get_selected()
        if tree_iter is not None:
            model.remove(tree_iter)
        self.update_recent_preview()

    def on_key_press(self, _widget, event) -> bool:
        if event.keyval in (Gdk.KEY_Return, Gdk.KEY_KP_Enter):
            self.on_launch()
            return True
        if event.keyval == Gdk.KEY_Escape:
            self.destroy()
            return True
        return False

    def on_launch(self, *_args) -> None:
        if self.notebook.get_current_page() == 0:
            selected = self.selected_recent()
            if selected is None:
                show_message("Please select a workspace.", Gtk.MessageType.WARNING)
                return
            name, command = selected
            launch_wezterm(name, command)
        else:
            folder = self.selected_folder()
            if not folder:
                show_message("Please select a folder.", Gtk.MessageType.WARNING)
                return
            port = self.port_entry.get_text().strip() or "8080"
            command = build_dev_command(self.current_mode(), port, self.dummy_check.get_active())
            launch_wezterm(folder, command)
        self.destroy()


def main() -> int:
    projects_root = ensure_projects_root()
    if not projects_root:
        return 0

    win = LauncherWindow(projects_root)
    win.show_all()
    # hide dummy until relevant; show_all would reveal it
    win.update_dummy_visibility()
    win.present()
    Gtk.main()
    return 0


if __name__ == "__main__":
    sys.exit(main())
