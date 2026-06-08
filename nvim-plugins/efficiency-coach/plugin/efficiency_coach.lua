-- Simple plugin loader for efficiency_coach
-- This runs at startup so users can call :EfficiencyCoachSuggest and :EfficiencyCoachPractice
vim.schedule(function()
  local ok, mod = pcall(require, 'efficiency_coach')
  if ok and mod and mod.setup then pcall(mod.setup) end
end)
