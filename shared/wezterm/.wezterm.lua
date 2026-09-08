-- Pull in the wezterm API
local wezterm = require("wezterm")
local mux = wezterm.mux
-- This will hold the configuration.
local config = wezterm.config_builder()

config.check_for_updates = true

-- This is where you actually apply your config choices

config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = true

-- Use the defaults as a base
config.hyperlink_rules = wezterm.default_hyperlink_rules()

-- For example, changing the color scheme:
config.color_scheme = "tokyonight_night"

-- The default background color
config.colors = {
  background = "#1c1c1c",
  cursor_bg = "#ffd900",
  tab_bar = {
    background = "#ffffff",
    -- The color of the inactive tab bar edge/divider
    inactive_tab_edge = "transparent",
  },
}

-- This function returns the suggested title for a tab.
-- It prefers the title that was set via `tab:set_title()`
-- or `wezterm cli set-tab-title`, but falls back to the
-- title of the active pane in that tab.
function tab_title(tab_info)
  local title = tab_info.tab_title
  -- if the tab title is explicitly set, take that
  if title and #title > 0 then
    return title
  end
  -- Otherwise, use the title from the active pane
  -- in that tab
  return tab_info.active_pane.title
end

-- The filled in variant of the < symbol
local SOLID_LEFT_ARROW = wezterm.nerdfonts.pl_right_hard_divider

-- The filled in variant of the > symbol
local SOLID_RIGHT_ARROW = wezterm.nerdfonts.pl_left_hard_divider

wezterm.on(
  'format-tab-title',
  function(tab, tabs, panes, config, hover, max_width)
    local title = tab_title(tab)
    if tab.is_active then
      return {
        { Background = { Color = '#966dd9' } },
        { Foreground = { Color = '#ffffff' } },
        { Text = '   ' .. title .. '   ' },
      }

    else
      return {
        { Background = { Color = '#4b5378' } },
        { Foreground = { Color = '#ffffff' } },
        { Text = '   ' .. title .. '   ' },
      }
    end
    if tab.is_last_active then
      -- Green color and append '*' to previously active tab.
      return {
        { Background = { Color = 'green' } },
        { Foreground = { Color = 'white' } },
        { Text = ' ' .. title .. '*' },
      }
    end
    return title
  end
)

config.font = wezterm.font("FiraCode Nerd Font", { weight = "DemiBold" })
config.font_size = 14
config.harfbuzz_features = { "calt=0", "clig=0", "liga=0" }

config.window_frame = {
  border_bottom_height = "0.1cell",
  border_bottom_color = "#123456",
}

config.audible_bell = "Disabled"

-- and finally, return the configuration to wezterm
wezterm.on("trigger-workspace", function(cmd)
  -- allow `wezterm start -- something` to affect what we spawn
  -- in our initial window
  local args = {}
  if cmd then
    args = cmd.args
  end

  -- Projects root is set by wezterm-launcher on first run; otherwise ~/Documents.
  local projects_root = wezterm.home_dir .. "/Documents"
  -- wezterm-launcher:projects-root
  if wezterm.target_triple == "x86_64-pc-windows-msvc" then
    projects_root = "C:/Users/Kevin/Documents"
  end
  -- wezterm-launcher:linux-projects-root
  if string.find(wezterm.target_triple, "linux") then
    projects_root = "/home/kevin/Documents"
  end
  local project_dir = projects_root .. "/" .. args[1]

  print(project_dir)

  local tab, pane, window = mux.spawn_window({
    workspace = "work",
    cwd = project_dir,
  })

  pane:send_text("nvim\r\n")

  if args[2] then
    local nodeTab, nodePane = window:spawn_tab({ cwd = project_dir })
    nodePane:send_text(args[2] .. "\r\n")
  else
    window:spawn_tab({ cwd = project_dir })
  end

  local gitTab, gitPane = window:spawn_tab({ cwd = project_dir })
  gitPane:send_text("lazygit\r\n")
  --
  tab:activate()
  mux.set_active_workspace("work")

  window:gui_window():maximize()
end)

-- Commands listed in ~/.config/wezterm/ai_clis.txt (written by setup_ai_clis).
local function load_ai_clis()
  local path = wezterm.home_dir .. "/.config/wezterm/ai_clis.txt"
  local file = io.open(path, "r")
  if not file then
    return {}
  end
  local clis = {}
  for line in file:lines() do
    line = line:match("^%s*(.-)%s*$")
    if line and #line > 0 and not line:match("^#") then
      table.insert(clis, line)
    end
  end
  file:close()
  return clis
end

local function spawn_ai_cli_tabs(window, cwd)
  for _, cmd in ipairs(load_ai_clis()) do
    local tab, pane = window:spawn_tab({ cwd = cwd })
    tab:set_title(cmd)
    pane:send_text(cmd .. "\r\n")
  end
end

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

    spawn_ai_cli_tabs(window, wezterm.home_dir)
    tab:activate()
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

config.keys = {
  {
    key = "v",
    mods = "CMD",
    action = wezterm.action.PasteFrom("Clipboard"),
  },
  {
    key = "j",
    mods = "CMD",
    action = wezterm.action.SendKey({
      key = "j",
      mods = "CTRL",
    }),
  },
  {
    key = "y",
    mods = "CMD",
    action = wezterm.action.SendKey({
      key = "y",
      mods = "CTRL",
    }),
  },
  {
    key = "o",
    mods = "CMD",
    action = wezterm.action.SendKey({
      key = "o",
      mods = "CTRL",
    }),
  },
  {
    key = "i",
    mods = "CMD",
    action = wezterm.action.SendKey({
      key = "i",
      mods = "CTRL",
    }),
  },
  {
    key = "d",
    mods = "CMD",
    action = wezterm.action.SendKey({
      key = "d",
      mods = "CTRL",
    }),
  },
  {
    key = "u",
    mods = "CMD",
    action = wezterm.action.SendKey({
      key = "u",
      mods = "CTRL",
    }),
  },
  {
    key = "n",
    mods = "CMD",
    action = wezterm.action.SendKey({
      key = "n",
      mods = "CTRL",
    }),
  },
  {
    key = "p",
    mods = "CMD",
    action = wezterm.action.SendKey({
      key = "p",
      mods = "CTRL",
    }),
  },
  {
    key = "h",
    mods = "CMD",
    action = wezterm.action.SendKey({
      key = "h",
      mods = "CTRL",
    }),
  },
  {
    key = "l",
    mods = "CMD",
    action = wezterm.action.SendKey({
      key = "l",
      mods = "CTRL",
    }),
  },
  {
    key = "k",
    mods = "CMD",
    action = wezterm.action.SendKey({
      key = "k",
      mods = "CTRL",
    }),
  },
  {
    key = "j",
    mods = "CMD",
    action = wezterm.action.SendKey({
      key = "j",
      mods = "CTRL",
    }),
  },
  {
    key = "b",
    mods = "CMD",
    action = wezterm.action.SendKey({
      key = "b",
      mods = "CTRL",
    }),
  },
  {
    key = "r",
    mods = "CMD",
    action = wezterm.action.SendKey({
      key = "r",
      mods = "CTRL",
    }),
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

return config


