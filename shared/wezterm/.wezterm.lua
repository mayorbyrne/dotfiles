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

local theme_dir = wezterm.home_dir .. "/.dotfiles/shared/theme/lua"
local elforest = dofile(theme_dir .. "/elforest/palette.lua")
local active_theme = dofile(theme_dir .. "/theme/active.lua")

config.color_schemes = {
  Elforest = {
    foreground = elforest.fg,
    background = elforest.bg,
    cursor_bg = elforest.yellow,
    cursor_fg = elforest.bg,
    cursor_border = elforest.yellow,
    selection_bg = elforest.bg3,
    selection_fg = elforest.fg_bright,
    split = elforest.bg4,
    scrollbar_thumb = elforest.bg3,
    ansi = elforest.ansi,
    brights = elforest.brights,
    tab_bar = {
      background = elforest.bg_dim,
      inactive_tab_edge = "transparent",
    },
  },
}

local ui_by_theme = {
  elforest = {
    active_bg = elforest.green,
    active_fg = elforest.bg,
    inactive_bg = elforest.bg2,
    inactive_fg = elforest.cyan,
    border = elforest.bg_dim,
  },
  classic = {
    active_bg = "#966dd9",
    active_fg = "#ffffff",
    inactive_bg = "#4b5378",
    inactive_fg = "#ffffff",
    border = "#123456",
  },
}
local ui = ui_by_theme[active_theme] or ui_by_theme.elforest

if active_theme == "classic" then
  config.color_scheme = "tokyonight_night"
  config.colors = {
    background = "#1c1c1c",
    cursor_bg = "#ffd900",
    tab_bar = {
      background = "#ffffff",
      inactive_tab_edge = "transparent",
    },
  }
else
  config.color_scheme = "Elforest"
end

-- Fancy tab bar pads tabs past the formatted text cells; match that padding to the tab colors.
local tab_bar_colors = active_theme == "classic" and config.colors.tab_bar or config.color_schemes.Elforest.tab_bar
tab_bar_colors.active_tab = { bg_color = ui.active_bg, fg_color = ui.active_fg }
tab_bar_colors.inactive_tab = { bg_color = ui.inactive_bg, fg_color = ui.inactive_fg }

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

local AGENT_NAMES = { claude = true, agent = true, codex = true }
local agent_colors = {
  working = { bg = elforest.yellow, fg = elforest.bg },
  error = { bg = elforest.red, fg = elforest.bg },
  idle = { bg = elforest.cyan, fg = elforest.bg },
}
if active_theme == "classic" then
  agent_colors = {
    working = { bg = "#ffd900", fg = "#1c1c1c" },
    error = { bg = "#c04040", fg = "#ffffff" },
    idle = { bg = "#4aa3a3", fg = "#ffffff" },
  }
end

local function normalize_cwd(cwd)
  cwd = (cwd or ""):gsub("\\", "/"):gsub("/+$", "")
  if wezterm.target_triple:find("windows") then
    cwd = cwd:lower()
  end
  return cwd
end

local function strip_bom(text)
  return (text or ""):gsub("^\239\187\191", "")
end

local function cwd_from_uri(cwd)
  if type(cwd) == "userdata" or type(cwd) == "table" then
    return cwd.file_path or ""
  end
  if type(cwd) == "string" then
    return cwd:gsub("^file://[^/]*/", "/"):gsub("^/([A-Za-z]:)", "%1")
  end
  return ""
end

local function agent_name_from(...)
  local function match(s)
    if not s or s == "" then
      return nil
    end
    local lower = s:lower()
    local base = lower:match("([^/\\]+)$") or lower
    base = base:gsub("%.exe$", "")
    local first = base:match("^(%S+)") or base
    if first == "cursor" or first == "cursor-agent" then
      return "agent"
    end
    if AGENT_NAMES[first] then
      return first
    end
    if lower:find("cursor agent", 1, true) or lower:find("cursor-agent", 1, true) then
      return "agent"
    end
    if first == "claude" or lower:find("claude", 1, true) then
      return "claude"
    end
    if first == "codex" or lower:find("codex", 1, true) then
      return "codex"
    end
    return nil
  end
  for i = 1, select("#", ...) do
    local name = match(select(i, ...))
    if name then
      return name
    end
  end
  return nil
end

local last_agent_state = {}
local last_agent_state_read = 0

local function load_agent_state()
  local now = os.time()
  if now == last_agent_state_read then
    return last_agent_state
  end
  last_agent_state_read = now

  local path = wezterm.home_dir .. "/.config/wezterm/agent_state.txt"
  local file = io.open(path, "r")
  local map = {}
  if not file then
    last_agent_state = map
    return map
  end

  local stale = now - (6 * 60 * 60)
  for line in file:lines() do
    line = strip_bom(line):match("^%s*(.-)%s*$")
    if line and #line > 0 and not line:match("^#") then
      local name, cwd, status, updated = line:match("^([^|]+)|([^|]+)|([^|]+)|(%d+)$")
      updated = tonumber(updated) or 0
      if name and AGENT_NAMES[name] and (updated == 0 or updated >= stale) then
        map[name .. "|" .. normalize_cwd(cwd)] = status
      end
    end
  end
  file:close()
  last_agent_state = map
  return map
end

local function lookup_agent_status(name, cwd)
  local state = load_agent_state()
  cwd = normalize_cwd(cwd)
  local exact = state[name .. "|" .. cwd]
  if exact then
    return exact
  end
  local fallback
  for key, status in pairs(state) do
    local key_name, key_cwd = key:match("^([^|]+)|(.+)$")
    if key_name == name then
      fallback = status
      if cwd ~= "" and key_cwd ~= "" then
        if cwd:sub(1, #key_cwd) == key_cwd or key_cwd:sub(1, #cwd) == cwd then
          return status
        end
      end
    end
  end
  return fallback
end

local function tab_agent_info(tab)
  local pane = tab.active_pane
  local name = agent_name_from(tab_title(tab), pane.title, pane.foreground_process_name)
  if not name then
    return nil
  end
  local cwd = normalize_cwd(cwd_from_uri(pane.current_working_dir))
  local status = lookup_agent_status(name, cwd) or "idle"
  return { name = name, status = status, pane_id = pane.pane_id, cwd = cwd }
end

local function working_agent_for_cwd(cwd)
  if not cwd or cwd == "" then
    return nil
  end
  local fallback
  for key, status in pairs(load_agent_state()) do
    if status == "working" then
      local name, key_cwd = key:match("^([^|]+)|(.+)$")
      if name and key_cwd then
        if key_cwd == cwd then
          return name
        end
        if cwd:sub(1, #key_cwd) == key_cwd or key_cwd:sub(1, #cwd) == cwd then
          fallback = name
        end
      end
    end
  end
  return fallback
end

local last_written_panes = ""

local function remembered_pane(name, cwd)
  local panes = wezterm.GLOBAL.agent_panes
  if type(panes) ~= "table" then
    return nil
  end
  return panes[tostring(name) .. "|" .. (cwd or "")]
end

local function remember_agent_pane(name, pane_id, cwd)
  if not name or pane_id == nil then
    return
  end
  local panes = wezterm.GLOBAL.agent_panes
  if type(panes) ~= "table" then
    panes = {}
  end
  panes[tostring(name) .. "|" .. (cwd or "")] = pane_id
  wezterm.GLOBAL.agent_panes = panes

  local lines = {}
  for key, id in pairs(panes) do
    table.insert(lines, key .. "|" .. tostring(id))
  end
  table.sort(lines)
  local text = table.concat(lines, "\n")
  if text == last_written_panes then
    return
  end
  last_written_panes = text
  local path = wezterm.home_dir .. "/.config/wezterm/agent_panes.txt"
  local file = io.open(path, "w")
  if file then
    file:write(text .. "\n")
    file:close()
  end
end

-- The filled in variant of the < symbol
local SOLID_LEFT_ARROW = wezterm.nerdfonts.pl_right_hard_divider

-- The filled in variant of the > symbol
local SOLID_RIGHT_ARROW = wezterm.nerdfonts.pl_left_hard_divider

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
  local title = tab_title(tab)
  local agent = tab_agent_info(tab)
  local bg = tab.is_active and ui.active_bg or ui.inactive_bg
  local fg = tab.is_active and ui.active_fg or ui.inactive_fg
  if agent then
    if agent.status == "working" then
      remember_agent_pane(agent.name, agent.pane_id, agent.cwd)
    end
    local colors = agent_colors[agent.status]
    if colors then
      bg = colors.bg
      fg = colors.fg
    end
  elseif tab.is_active then
    local cwd = normalize_cwd(cwd_from_uri(tab.active_pane.current_working_dir))
    local name = working_agent_for_cwd(cwd)
    if name and not remembered_pane(name, cwd) then
      remember_agent_pane(name, tab.active_pane.pane_id, cwd)
    end
  end
  return {
    { Background = { Color = bg } },
    { Foreground = { Color = fg } },
    { Text = "   " .. title .. "   " },
  }
end)

config.font = wezterm.font("FiraCode Nerd Font", { weight = "DemiBold" })
config.font_size = 14
config.harfbuzz_features = { "calt=0", "clig=0", "liga=0" }
-- Spawn close to a maximized cell grid so ConPTY does not reflow the
-- first PowerShell prompt from 80x24 to full screen (C wraps to the edge).
config.initial_cols = 220
config.initial_rows = 50

config.window_frame = {
  border_bottom_height = "0.1cell",
  border_bottom_color = ui.border,
}

config.audible_bell = "Disabled"
config.status_update_interval = 1000

-- Commands listed in ~/.config/wezterm/ai_clis.txt (written by setup_ai_clis).
local function load_ai_clis()
  local path = wezterm.home_dir .. "/.config/wezterm/ai_clis.txt"
  local file = io.open(path, "r")
  if not file then
    return {}
  end
  local clis = {}
  for line in file:lines() do
    line = line:gsub("^98791", ""):match("^%s*(.-)%s*$")
    if line and #line > 0 and not line:match("^#") then
      table.insert(clis, line)
    end
  end
  file:close()

  -- Always order tabs Cursor, Claude, Codex; anything else keeps file order after.
  local rank = { agent = 1, claude = 2, codex = 3 }
  local ordered = {}
  for index, cmd in ipairs(clis) do
    table.insert(ordered, { cmd = cmd, index = index, rank = rank[cmd:match("^%S+")] or 99 })
  end
  table.sort(ordered, function(a, b)
    if a.rank ~= b.rank then
      return a.rank < b.rank
    end
    return a.index < b.index
  end)

  local sorted = {}
  for _, entry in ipairs(ordered) do
    table.insert(sorted, entry.cmd)
  end
  return sorted
end

-- Projects root is machine-specific, so it lives outside the repo.
-- Written by wezterm-launcher on first run; defaults to ~/Documents.
local function load_projects_root()
  local default_root = wezterm.home_dir .. "/Documents"
  local file = io.open(wezterm.home_dir .. "/.config/wezterm/projects_root.txt", "r")
  if not file then
    return default_root
  end

  local root = file:read("l") or ""
  file:close()
  root = root:gsub("^98791", "")
  root = root:match("^%s*(.-)%s*$"):gsub("\\", "/")
  if #root == 0 then
    return default_root
  end
  return root
end

local function spawn_ai_cli_tabs(window, cwd)
  for _, cmd in ipairs(load_ai_clis()) do
    local tab, pane = window:spawn_tab({ cwd = cwd })
    tab:set_title(cmd)
    pane:send_text(cmd .. "\r\n")
  end
end

-- Estimate a full-screen cell size so the first paint is not 80x24.
local function fullscreen_cells()
  local active = wezterm.gui.screens().active
  return {
    cols = math.max(80, math.floor(active.width / 8)),
    rows = math.max(24, math.floor(active.height / 18)),
    x = active.x,
    y = active.y,
  }
end

-- and finally, return the configuration to wezterm
wezterm.on("trigger-workspace", function(cmd)
  -- allow `wezterm start -- something` to affect what we spawn
  -- in our initial window
  local args = {}
  if cmd then
    args = cmd.args
  end

  local workspace = args[1] or "work"
  local project_dir = load_projects_root() .. "/" .. workspace

  local tab, pane, window = mux.spawn_window({
    workspace = workspace,
    cwd = project_dir,
  })

  tab:set_title("nvim")
  pane:send_text("nvim\r\n")

  if args[2] then
    local nodeTab, nodePane = window:spawn_tab({ cwd = project_dir })
    nodeTab:set_title("server")
    nodePane:send_text(args[2] .. "\r\n")
  else
    local shellTab = window:spawn_tab({ cwd = project_dir })
    shellTab:set_title("shell")
  end

  local gitTab, gitPane = window:spawn_tab({ cwd = project_dir })
  gitTab:set_title("lazygit")
  gitPane:send_text("lazygit\r\n")

  spawn_ai_cli_tabs(window, project_dir)

  tab:activate()
  mux.set_active_workspace(workspace)

  window:gui_window():maximize()
end)

wezterm.on("gui-startup", function(cmd)
  cmd = cmd or {}

  if cmd.args then
    wezterm.emit("trigger-workspace", cmd)
  else
    local screen = fullscreen_cells()
    local tab, pane, window = mux.spawn_window({
      width = screen.cols,
      height = screen.rows,
      position = {
        x = screen.x,
        y = screen.y,
        origin = "ScreenCoordinateSystem",
      },
    })

    spawn_ai_cli_tabs(window, wezterm.home_dir)
    tab:activate()
    -- Maximize after extra tabs exist so the tab bar does not resize
    -- the pane after PowerShell has already painted the banner.
    window:gui_window():maximize()
  end
end)

local last_cwd = ""
local last_repo = ""

local function apply_activate_request()
  local path = wezterm.home_dir .. "/.config/wezterm/activate_request.txt"
  local file = io.open(path, "r")
  if not file then
    return
  end
  local raw = strip_bom(file:read("*a") or "")
  file:close()
  os.remove(path)
  local id = tonumber(raw and raw:match("(%d+)"))
  if not id then
    return
  end
  local mux = wezterm.mux
  for _, mux_win in ipairs(mux.all_windows()) do
    for _, tab in ipairs(mux_win:tabs()) do
      for _, p in ipairs(tab:panes()) do
        if p:pane_id() == id then
          mux.set_active_workspace(mux_win:get_workspace())
          p:activate()
          local gui = mux_win:gui_window()
          if gui then
            gui:focus()
          end
          return
        end
      end
    end
  end
end

wezterm.on("window-focus-changed", function()
  apply_activate_request()
end)

wezterm.on("update-right-status", function(window, pane)
  apply_activate_request()
  local cwd = ""
  local proc = pane:get_foreground_process_info()
  if proc and proc.cwd then
    cwd = proc.cwd
  else
    cwd = cwd_from_uri(pane:get_current_working_dir())
  end

  local repo_name = ""
  if cwd ~= "" then
    if cwd == last_cwd then
      repo_name = last_repo
    else
      local success, stdout = wezterm.run_child_process({ "git", "-C", cwd, "rev-parse", "--show-toplevel" })
      if success then
        local root = stdout:gsub("%s+$", "")
        repo_name = root:match("([^\\/]+)$") or ""
      end
      last_cwd = cwd
      last_repo = repo_name
    end
  end

  if repo_name ~= "" then
    window:set_right_status(wezterm.format({
      { Background = { Color = ui.active_bg } },
      { Foreground = { Color = ui.active_fg } },
      { Text = "  " .. repo_name .. "  " },
    }))
  else
    window:set_right_status("")
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
    key = "v",
    mods = "CTRL",
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
