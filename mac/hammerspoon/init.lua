local dotfiles = os.getenv("HOME") .. "/.dotfiles"

-- Held so the poll timers are not garbage collected mid-poll.
local pickerTimers = {}

-- Python.app launched from Hammerspoon never activates itself, so focus its
-- window by pid once Tk has mapped it. By pid, not bundle id: an AppleScript
-- bundle-id activate relaunches Python.app with whatever script it last ran.
local function launchPicker(script)
  local task = hs.task.new("/usr/local/bin/python3", nil, {script})
  task:start()
  local tries = 0
  pickerTimers[script] = hs.timer.doUntil(
    function() return tries > 30 end,
    function()
      tries = tries + 1
      local app = hs.application.applicationForPID(task:pid())
      local win = app and app:mainWindow()
      if win then
        win:focus()
        tries = 99
      end
    end,
    0.1
  )
end

hs.hotkey.bind({"alt", "shift"}, "r", function()
  launchPicker(dotfiles .. "/mac/wezterm-launcher/launcher.py")
end)

hs.hotkey.bind({"alt", "shift"}, "p", function()
  launchPicker(dotfiles .. "/mac/script-selector/script-selector.py")
end)
