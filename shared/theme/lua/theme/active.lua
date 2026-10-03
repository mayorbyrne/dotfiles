-- Plain io so wezterm (via dofile) and neovim share one reader.
local home = os.getenv("USERPROFILE") or os.getenv("HOME")
local file = io.open(home .. "/.dotfiles/shared/theme/theme.txt", "r")
if not file then
  return "elforest"
end
local name = (file:read("l") or ""):match("^%s*(.-)%s*$")
file:close()
return name ~= "" and name or "elforest"
