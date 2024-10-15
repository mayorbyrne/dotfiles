-- Pull in the wezterm API
local wezterm = require("wezterm")
local mux = wezterm.mux
-- This will hold the configuration.
local config = wezterm.config_builder()

config.check_for_updates = true
config.show_update_window = true

-- This is where you actually apply your config choices

config.hide_tab_bar_if_only_one_tab = true
-- Use the defaults as a base
config.hyperlink_rules = wezterm.default_hyperlink_rules()

-- For example, changing the color scheme:
config.color_scheme = "tokyonight_night"

-- The default background color
config.colors = {
  background = "#1c1c1c",
  cursor_bg = "#ffd900",
}

config.font = wezterm.font("Fira Code", { weight = "DemiBold" })
config.font_size = 12
config.harfbuzz_features = { "calt=0", "clig=0", "liga=0" }

config.window_frame = {
  border_bottom_height = "0.1cell",
  border_bottom_color = "#123456",
}

config.audible_bell = "Disabled"

-- and finally, return the configuration to wezterm
wezterm.on("gui-startup", function(cmd)
  -- Pick the active screen to maximize into, there are also other options, see the docs.
  local active = wezterm.gui.screens().active

  -- Set the window coords on spawn.
  local tab, pane, window = mux.spawn_window(cmd or {
    x = active.x,
    y = active.y,
    width = active.width,
    height = active.height,
  })

  -- You probably don't need both, but you can also set the positions after spawn.
  window:gui_window():set_position(active.x, active.y)
  window:gui_window():set_inner_size(active.width, active.height)
end)

config.default_cursor_style = "BlinkingBlock"
config.cursor_blink_rate = 500
config.cursor_blink_ease_in = "Constant"
config.cursor_blink_ease_out = "Constant"

return config
