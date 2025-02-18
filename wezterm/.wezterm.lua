-- Pull in the wezterm API
local wezterm = require("wezterm")
local mux = wezterm.mux
-- This will hold the configuration.
local config = wezterm.config_builder()

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end

config.wsl_domains = {
  {
    -- The name of this specific domain.  Must be unique amonst all types
    -- of domain in the configuration file.
    name = 'WSL:Ubuntu',

    -- The name of the distribution.  This identifies the WSL distribution.
    -- It must match a valid distribution from your `wsl -l -v` output in
    -- order for the domain to be useful.
    distribution = 'Ubuntu',
    default_cwd = '~',
  },
}
config.default_domain = 'WSL:Ubuntu'

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

-- config.font = wezterm.font("Fira Code", { weight = "DemiBold" })
config.font = wezterm.font("JetBrains Mono", { weight = "Bold" })
config.font_size = 9
config.harfbuzz_features = { "calt=0", "clig=0", "liga=0" }

config.window_frame = {
  -- border_bottom_height = "0.6cell",
  border_bottom_color = "#123456",
}

config.audible_bell = "Disabled"

config.window_decorations = "INTEGRATED_BUTTONS|RESIZE";

-- and finally, return the configuration to wezterm
wezterm.on("gui-startup", function(cmd)
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
  window:gui_window():maximize()
  -- window:gui_window():set_inner_size(active.width, active.height - 20)
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

return config
