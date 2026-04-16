local yank_group = vim.api.nvim_create_augroup("highlight-yank", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking text",
  group = yank_group,
  callback = function()
    vim.highlight.on_yank()
  end,
})

local trim_group = vim.api.nvim_create_augroup("trim-trailing-whitespace", { clear = true })
vim.api.nvim_create_autocmd("BufWritePre", {
  group = trim_group,
  pattern = {
    "*.lua",
    "*.js",
    "*.jsx",
    "*.ts",
    "*.tsx",
    "*.json",
    "*.jsonc",
    "*.css",
    "*.scss",
    "*.html",
    "*.md",
    "*.dart",
    "*.py",
    "*.yaml",
    "*.yml",
  },
  callback = function()
    local view = vim.fn.winsaveview()
    vim.cmd([[silent! %s/\s\+$//e]])
    vim.fn.winrestview(view)
  end,
})
