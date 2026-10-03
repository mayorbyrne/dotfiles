-- Single source for Elforest colors. Loaded by neovim (as a plugin) and wezterm (via dofile).
local p = {
  bg_dim = "#0b100e",
  bg = "#121a16",
  bg1 = "#1a241f",
  bg2 = "#1f2a25",
  bg3 = "#2a3832",
  bg4 = "#3a4a42",
  grey = "#5e7268",
  comment = "#8096c0",
  fg = "#9fe6d6",
  fg_bright = "#e0fff6",

  red = "#f07878",
  orange = "#f2a65a",
  yellow = "#f0d870",
  green = "#b6e07a",
  cyan = "#5fd7c7",
  blue = "#80a8e8",
  magenta = "#e58fd0",
  purple = "#d699b6",

  bright_red = "#ff9090",
  bright_green = "#caf090",
  bright_yellow = "#fff08a",
  bright_blue = "#9cc0ff",
  bright_magenta = "#f5a8e2",
  bright_cyan = "#80f0e0",

  diff_add = "#1f3320",
  diff_change = "#1e2c3a",
  diff_delete = "#3a1f22",
  diff_text = "#2b4258",
}

p.ansi = { p.bg2, p.red, p.green, p.yellow, p.blue, p.magenta, p.cyan, p.fg }
p.brights = {
  p.grey,
  p.bright_red,
  p.bright_green,
  p.bright_yellow,
  p.bright_blue,
  p.bright_magenta,
  p.bright_cyan,
  p.fg_bright,
}

return p
