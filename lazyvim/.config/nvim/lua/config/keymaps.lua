-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
-- vim.keymap.del('n', '<leader>xx')

-- [[ Basic Keymaps ]]
vim.keymap.set("n", "d", '"_d', {})
vim.keymap.set("v", "d", '"_d', {})
vim.keymap.set("n", "c", '"_c', {})
vim.keymap.set("v", "c", '"_c', {})

-- do not map c or d in SELECT mode
vim.keymap.set("s", "c", "c", {})
vim.keymap.set("s", "d", "d", {})

vim.keymap.set("i", "<C-J>", 'copilot#Accept("\\<CR>")', {
  expr = true,
  replace_keycodes = false,
})
vim.keymap.set("n", "<leader>dd", ":Dashboard<CR>")
vim.keymap.set("n", "<leader>dr", ":Telescope oldfiles<CR>")
vim.keymap.set("n", "<leader>pp", ":Prettier<CR>")
-- vim.keymap.set("n", "<leader>ee", ":Telescope file_browser<CR>")

vim.keymap.set("n", "<leader>bn", ":bn<CR>")
vim.keymap.set("n", "<leader>bp", ":bp<CR>")
vim.keymap.set("t", "<leader>bd", ":bd!<CR>")
vim.keymap.set("n", "<leader>bd", function()
  if vim.bo.buftype == "terminal" then
    vim.cmd("bd!")
  else
    vim.cmd("bd")
  end
end)

vim.keymap.set("n", "<leader>kb", ':VimuxRunCommand "webdev serve"<CR>')
vim.keymap.set("n", "<leader>kg", ':VimuxRunCommand "lazygit"<CR>')
vim.keymap.set("n", "<leader>gi", ":Git<CR>", { desc = "Git Fugitive" })

vim.keymap.set("n", "<leader>xx", ":Trouble diagnostics<CR>", { desc = "Trouble Open" })
vim.keymap.set("n", "<leader>xc", ":Trouble close<CR>", { desc = "Trouble Close" })
-- vim.keymap.set("n", "<leader>xp", ":Trouble prev<CR>", { desc = "Trouble Previous" })
-- vim.keymap.set("n", "<leader>xn", ":Trouble next<CR>", { desc = "Trouble Next" })
vim.keymap.set("n", "<leader>xp", function()
  require("trouble").prev()
end, { desc = "Trouble Previous" })

vim.keymap.set("n", "<leader>xn", function()
  require("trouble").next()
end, { desc = "Trouble Next" })

vim.keymap.set("n", "<leader>qq", ":copen<CR>", { desc = "Quickfix Open" })
vim.keymap.set("n", "<leader>qo", ":copen<CR>", { desc = "Quickfix Open" })
vim.keymap.set("n", "<leader>qc", ":cclose<CR>", { desc = "Quickfix Close" })
vim.keymap.set("n", "<leader>qn", ":cnext<CR>", { desc = "Quickfix Next" })
vim.keymap.set("n", "<leader>qp", ":cprev<CR>", { desc = "Quickfix Previous" })
vim.keymap.set("n", "<leader>qf", ":cfirst<CR>", { desc = "Quickfix First" })
vim.keymap.set("n", "<leader>ql", ":clast<CR>", { desc = "Quickfix Last" })

vim.keymap.set("n", "<leader>lr", ":LspRestart<CR>", { desc = "LSP Restart" })
vim.keymap.set("n", "<leader>li", ":LspInfo<CR>", { desc = "LSP Info" })

