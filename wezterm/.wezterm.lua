-- Pull in the wezterm API
local wezterm = require("wezterm")
local mux = wezterm.mux
-- This will hold the configuration.
local config = wezterm.config_builder()
local launch_menu = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end

--- Set Pwsh as the default on Windows
config.default_prog = { "powershell.exe", "-NoLogo" }

config.tab_bar_at_bottom = true

config.check_for_updates = true

-- This is where you actually apply your config choices

config.hide_tab_bar_if_only_one_tab = false
-- Use the defaults as a base
config.hyperlink_rules = wezterm.default_hyperlink_rules()

-- For example, changing the color scheme:
config.color_scheme = "tokyonight_night"

-- The default background color
config.colors = {
  background = "#1c1c1c",
  cursor_bg = "#ffd900",
}

config.font = wezterm.font("FiraCode Nerd Font", { weight = "DemiBold" })
config.font_size = 12
config.harfbuzz_features = { "calt=0", "clig=0", "liga=0" }

config.window_frame = {
  -- border_bottom_height = "0.6cell",
  border_bottom_color = "#123456",
}

config.audible_bell = "Disabled"

config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"

wezterm.on("trigger-workspace", function(cmd)
  -- allow `wezterm start -- something` to affect what we spawn
  -- in our initial window
  local args = {}
  if cmd then
    args = cmd.args
  end

  local project_dir = "d:/git/" .. args[1]
  local tab, pane, window = mux.spawn_window({
    workspace = "work",
    cwd = project_dir,
  })

  pane:send_text("nvim\r\n")

  local nodeTab, nodePane = window:spawn_tab({ cwd = project_dir })
  nodePane:send_text(args[2] .. "\r\n")

  local gitTab, gitPane = window:spawn_tab({ cwd = project_dir })
  gitPane:send_text("lazygit\r\n")
  --
  tab:activate()
  mux.set_active_workspace("work")

  window:gui_window():maximize()
end)

-- and finally, return the configuration to wezterm
wezterm.on("gui-startup", function(cmd)
  local count = 0
  cmd = cmd or {}

  if cmd.args then
    wezterm.emit("trigger-workspace", cmd)
  else
    -- Pick the active screen to maximize into, there are also other options, see the docs.
    local active = wezterm.gui.screens().active
    -- Set the window coords on spawn.
    local tab, pane, window = mux.spawn_window(cmd or {
      -- x = active.x,
      -- y = active.y,
      -- width = active.width,
      -- height = active.height,
    })

    -- You probably don't need both, but you can also set the positions after spawn.
    window:gui_window():set_position(active.x, active.y)
    window:gui_window():set_inner_size(active.width, active.height)
    window:gui_window():maximize()
  end
end)

config.default_cursor_style = "BlinkingBlock"
config.cursor_blink_rate = 500
config.cursor_blink_ease_in = "Constant"
config.cursor_blink_ease_out = "Constant"

if wezterm.target_triple == "x86_64-pc-windows-msvc" then
  config.default_prog = { "powershell.exe" }
else
  config.default_prog = wezterm.Default_prog
end

config.window_frame = {
  -- The font used in the tab bar.
  -- Roboto Bold is the default; this font is bundled
  -- with wezterm.
  -- Whatever font is selected here, it will have the
  -- main font setting appended to it to pick up any
  -- fallback fonts you may have used there.
  font = wezterm.font({ family = "Roboto", weight = "Bold" }),

  -- The size of the font in the tab bar.
  -- Default to 10.0 on Windows but 12.0 on other systems
  font_size = 9.0,
}

config.colors = {
  tab_bar = {
    -- The color of the inactive tab bar edge/divider
    inactive_tab_edge = "white",
    -- The active tab is the one that has focus in the window
    active_tab = {
      -- The color of the background area for the tab
      bg_color = "#a37ade",
      -- The color of the text for the tab
      fg_color = "#fff",
    },
    inactive_tab = {
      -- The color of the background area for the tab
      bg_color = "#525c81",
      -- The color of the text for the tab
      fg_color = "white",
    },
  },
}

config.keys = {
  {
    key = "w",
    mods = "CTRL",
    action = wezterm.action.CloseCurrentPane({ confirm = false }),
  },
  {
    key = "v",
    mods = "CTRL",
    action = wezterm.action.PasteFrom("Clipboard"),
  },
  {
    key = "t",
    mods = "CTRL",
    action = wezterm.action.SpawnTab("CurrentPaneDomain"),
  },
  {
    key = "w",
    mods = "CTRL",
    action = wezterm.action.CloseCurrentTab({ confirm = true }),
  },
  {
    key = "1",
    mods = "ALT",
    action = wezterm.action.ActivateTab(0),
  },
  {
    key = "2",
    mods = "ALT",
    action = wezterm.action.ActivateTab(1),
  },
  {
    key = "3",
    mods = "ALT",
    action = wezterm.action.ActivateTab(2),
  },
  {
    key = "4",
    mods = "ALT",
    action = wezterm.action.ActivateTab(3),
  },
  {
    key = "5",
    mods = "ALT",
    action = wezterm.action.ActivateTab(4),
  },
  {
    key = "6",
    mods = "ALT",
    action = wezterm.action.ActivateTab(5),
  },
  {
    key = "7",
    mods = "ALT",
    action = wezterm.action.ActivateTab(6),
  },
}

for i = 1, 8 do
  -- CTRL+ALT + number to move to that position
  table.insert(config.keys, {
    key = tostring(i),
    mods = "CTRL|ALT",
    action = wezterm.action.MoveTab(i - 1),
  })
end

--- Default config settings
config.launch_menu = launch_menu

return config
