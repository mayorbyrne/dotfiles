-- Pull in the wezterm API
local wezterm = require("wezterm")
local mux = wezterm.mux
-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices

config.hide_tab_bar_if_only_one_tab = true
-- Use the defaults as a base
config.hyperlink_rules = wezterm.default_hyperlink_rules()

-- For example, changing the color scheme:
config.color_scheme = "Dark+"

-- The default background color
config.colors = {
  background = "black",
}

config.font = wezterm.font("Fira Code", { weight = "Bold" })
config.font_size = 11.6
config.harfbuzz_features = { "calt=0", "clig=0", "liga=0" }

config.window_frame = {
  border_bottom_height = "0.1cell",
  border_bottom_color = "#123456",
}

-- and finally, return the configuration to wezterm
wezterm.on("gui-startup", function(cmd)
  local tab, pane, window = mux.spawn_window(cmd or {})
  window:gui_window():maximize()
end)

return config
