-- Pull in the wezterm API
local wezterm = require("wezterm")
local mux = wezterm.mux;
-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices
wezterm.on('gui-startup', function(cmd)
  local tab, pane, window = mux.spawn_window(cmd or {})
  window:gui_window():maximize()
end)

config.hide_tab_bar_if_only_one_tab = true

-- For example, changing the color scheme:
-- config.color_scheme = "Abernathy"

-- The default background color
config.colors = {
  background = "black",
}

config.font = wezterm.font("Fira Code", { weight = "Bold" })
config.harfbuzz_features = { "calt=0", "clig=0", "liga=0" }

-- and finally, return the configuration to wezterm
return config
