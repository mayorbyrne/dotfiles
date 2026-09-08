-- VSCode Neovim init file
-- This loads when Neovim is running inside VSCode

-- Set leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Black hole register mappings (delete/change without yanking)
vim.keymap.set("n", "d", '"_d', {})
vim.keymap.set("v", "d", '"_d', {})
vim.keymap.set("n", "D", '"_D', {})
vim.keymap.set("n", "c", '"_c', {})
vim.keymap.set("v", "c", '"_c', {})
vim.keymap.set("n", "C", '"_C', {})
vim.keymap.set("n", "diw", '"_diw', {})
vim.keymap.set("v", "diw", '"_diw', {})
vim.keymap.set("n", "ciw", '"_ciw', {})
vim.keymap.set("v", "ciw", '"_ciw', {})

-- Do not map c or d in SELECT mode
vim.keymap.set("s", "c", "c", {})
vim.keymap.set("s", "d", "d", {})

-- VSCode specific keybindings using vscode.call
local vscode = require('vscode')

-- Clear search highlight
vim.keymap.set("n", "<Esc>", function()
  vscode.call("nohl")
end)

-- Window/Split navigation
vim.keymap.set("n", "<C-h>", function() vscode.call("workbench.action.navigateLeft") end)
vim.keymap.set("n", "<C-l>", function() vscode.call("workbench.action.navigateRight") end)
vim.keymap.set("n", "<C-k>", function() vscode.call("workbench.action.navigateUp") end)
vim.keymap.set("n", "<C-j>", function() vscode.call("workbench.action.navigateDown") end)

-- Search
vim.keymap.set("n", "<leader>sf", function() vscode.call("workbench.action.quickOpen") end)
vim.keymap.set("n", "<leader>sg", function() vscode.call("workbench.action.findInFiles") end)
vim.keymap.set("n", "<leader>sr", function() vscode.call("workbench.action.replaceInFiles") end)
vim.keymap.set("n", "<leader>ss", function() vscode.call("workbench.action.showAllEditors") end)
vim.keymap.set("n", "<leader>sd", function() vscode.call("workbench.actions.view.problems") end)
vim.keymap.set("n", "<leader>dr", function() vscode.call("workbench.action.openRecent") end)
vim.keymap.set("n", "<leader><leader>", function() vscode.call("workbench.action.showAllEditors") end)

-- LSP
vim.keymap.set("n", "gd", function() vscode.call("editor.action.revealDefinition") end)
vim.keymap.set("n", "gr", function() vscode.call("references-view.findReferences") end)
vim.keymap.set("n", "gI", function() vscode.call("editor.action.goToImplementation") end)
vim.keymap.set("n", "gD", function() vscode.call("editor.action.revealDeclaration") end)
vim.keymap.set("n", "K", function() vscode.call("editor.action.showHover") end)
vim.keymap.set("n", "<leader>ca", function() vscode.call("editor.action.quickFix") end)
vim.keymap.set("n", "<leader>rn", function() vscode.call("editor.action.rename") end)

-- Code formatting
vim.keymap.set("n", "<leader>cf", function() vscode.call("editor.action.formatDocument") end)
vim.keymap.set("n", "<leader>pp", function() vscode.call("editor.action.formatDocument") end)

-- Buffer management
vim.keymap.set("n", "<leader>bn", function() vscode.call("workbench.action.nextEditor") end)
vim.keymap.set("n", "<leader>bp", function() vscode.call("workbench.action.previousEditor") end)
vim.keymap.set("n", "<leader>bd", function() vscode.call("workbench.action.closeActiveEditor") end)
vim.keymap.set("n", "<leader>bc", function() vscode.call("workbench.action.closeOtherEditors") end)
vim.keymap.set("n", "<leader>q", function() vscode.call("workbench.action.closeActiveEditor") end)

-- Splits
vim.keymap.set("n", "<leader>wv", function() vscode.call("workbench.action.splitEditor") end)
vim.keymap.set("n", "<leader>ws", function() vscode.call("workbench.action.splitEditorDown") end)

-- File explorer
vim.keymap.set("n", "<leader>tt", function() vscode.call("workbench.action.toggleSidebarVisibility") end)
vim.keymap.set("n", "<leader>tf", function() vscode.call("workbench.files.action.focusFilesExplorer") end)

-- Diagnostics
vim.keymap.set("n", "<leader>xx", function() vscode.call("workbench.actions.view.problems") end)
vim.keymap.set("n", "<leader>xn", function() vscode.call("editor.action.marker.next") end)
vim.keymap.set("n", "<leader>xp", function() vscode.call("editor.action.marker.prev") end)

-- Git
vim.keymap.set("n", "<leader>gi", function() vscode.call("workbench.view.scm") end)

-- Visual mode search
vim.keymap.set("v", "*", function() vscode.call("editor.action.addSelectionToNextFindMatch") end)
