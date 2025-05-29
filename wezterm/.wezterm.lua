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

config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"

wezterm.on("trigger-workspace", function(cmd)
	-- allow `wezterm start -- something` to affect what we spawn
	-- in our initial window
	local args = {}
	if cmd then
		args = cmd.args
	end

	local project_dir = "c:/users/kevin/documents/code/" .. args[1]
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

config.keys = {
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

--- Default config settings
config.launch_menu = launch_menu

return config
