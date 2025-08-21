-- Remove netrw setting since netrw is disabled in init.lua
-- vim.g.netrw_sort_options = "i"

vim.opt.termguicolors = true

-- MiniMap settings
vim.g.minimap_width = 10
vim.g.minimap_auto_start = 1
vim.g.minimap_auto_start_win_enter = 1

-- Indentation settings
vim.o.softtabstop = 2
vim.o.shiftwidth = 2
vim.o.expandtab = true
vim.o.tabstop = 2

-- Cursor settings
vim.o.guicursor = "i:ver25,a:blinkwait60-blinkoff500-blinkon500"

-- Folding with Treesitter
vim.o.foldlevel = 20
vim.o.foldmethod = "expr"
vim.o.foldexpr = "nvim_treesitter#foldexpr()"

-- Remove lsc_auto_map to avoid conflicts with nvim-lspconfig
-- [[
-- vim.cmd([[
-- let g:lsc_auto_map = {
--     \ 'GoToDefinition': 'gdd',
--     \ 'GoToDefinitionSplit': ['<C-W>]', '<C-W><C-]>'],
--     \ 'FindReferences': 'gr',
--     \ 'NextReference': '<C-n>',
--     \ 'PreviousReference': '<C-p>',
--     \ 'FindImplementations': 'gI',
--     \ 'FindCodeActions': 'ga',
--     \ 'Rename': 'gR',
--     \ 'ShowHover': v:true,
--     \ 'DocumentSymbol': 'go',
--     \ 'WorkspaceSymbol': 'gS',
--     \ 'SignatureHelp': 'gm',
--     \ 'Completion': 'completefunc',
--     \}
-- ]])
-- ]]

-- Visual Star Search
vim.cmd([[
function! VisualStarSearchSet(cmdtype,...)
  let temp = @"
  normal! gvy
  if !a:0 || a:1 != 'raw'
    let @" = escape(@", a:cmdtype.'\*')
  endif
  let @/ = substitute(@", '\n', '\\n', 'g')
  let @/ = substitute(@/, '\[', '\\[', 'g')
  let @/ = substitute(@/, '\~', '\\~', 'g')
  let @/ = substitute(@/, '\.', '\\.', 'g')
  let @" = temp
endfunction

xnoremap * :<C-u>call VisualStarSearchSet('/')<CR>/<C-R>=@/<CR><CR>
xnoremap # :<C-u>call VisualStarSearchSet('?')<CR>?<C-R>=@/<CR><CR>

if maparg('<leader>*', 'n') == ''
  nnoremap <leader>* :execute 'noautocmd vimgrep /\V' . substitute(escape(expand("<cword>"), '\'), '\n', '\\n', 'g') . '/ **'<CR>
endif
if maparg('<leader>*', 'v') == ''
  vnoremap <leader>* :<C-u>call VisualStarSearchSet('/')<CR>:execute 'noautocmd vimgrep /' . @/ . '/ **'<CR>
endif
]])

-- Trailing whitespace removal
vim.cmd([[
autocmd BufWritePre *.pl %s/\s\+$//e
autocmd FileType dart,js,ts,html,css,md autocmd BufWritePre <buffer> %s/\s\+$//e
]])

-- [[ Basic Keymaps ]]
vim.keymap.set("n", "d", '"_d', {})
vim.keymap.set("v", "d", '"_d', {})
vim.keymap.set("n", "c", '"_c', {})
vim.keymap.set("v", "c", '"_c', {})
vim.keymap.set("n", "diw", '"_diw', {})
vim.keymap.set("v", "diw", '"_diw', {})
vim.keymap.set("n", "ciw", '"_ciw', {})
vim.keymap.set("v", "ciw", '"_ciw', {})

vim.keymap.set("s", "c", "c", {})
vim.keymap.set("s", "d", "d", {})

vim.keymap.set("n", "<leader>bc", ":xc<CR>:%bd|e#<CR>", { desc = "Close all buffers except current" })

vim.keymap.set("i", "<C-J>", 'copilot#Accept("\\<CR>")', {
  expr = true,
  replace_keycodes = false,
})
vim.g.copilot_no_tab_map = true

vim.keymap.set("n", "<leader>dd", ":Dashboard<CR>")
vim.keymap.set("n", "<leader>dr", ":Telescope oldfiles<CR>")
vim.keymap.set("n", "<leader>pp", ":Prettier<CR>")
-- vim.keymap.set('n', '<leader>ee', ':Telescope file_browser<CR>')

vim.keymap.set("n", "<leader>bn", ":xc<CR>:bn<CR>")
vim.keymap.set("n", "<leader>bp", ":xc<CR>:bp<CR>")
vim.keymap.set("t", "<leader>bd", ":xc<CR>:bd!<CR>")
vim.keymap.set("n", "<leader>bd", function()
  if vim.bo.buftype == "terminal" then
    vim.cmd("bd!")
  else
    vim.cmd("bd")
  end
end)

vim.cmd("ca wq bd!")
vim.cmd("ca q bd!")
vim.cmd("ca Quit quit")

vim.keymap.set("n", "<leader>kb", ':VimuxRunCommand "webdev serve"<CR>')
vim.keymap.set("n", "<leader>kg", ':VimuxRunCommand "lazygit"<CR>')
vim.keymap.set("n", "<leader>gi", ":Git<CR>", { desc = "Git Fugitive" })

vim.keymap.set("n", "<leader>e", ':lua vim.diagnostic.open_float(0, {scope="line"})<CR>', { desc = "Line Diagnostics" })

vim.keymap.set("n", "<leader>xx", ":Trouble diagnostics<CR>", { desc = "Trouble Open" })
vim.keymap.set("n", "<leader>xc", ":Trouble close<CR>", { desc = "Trouble Close" })
vim.keymap.set("n", "<leader>xp", ":Trouble prev<CR>", { desc = "Trouble Previous" })
vim.keymap.set("n", "<leader>xn", ":Trouble next<CR>", { desc = "Trouble Next" })

vim.keymap.set("n", "<leader>qq", ":copen<CR>", { desc = "Quickfix Open" })
vim.keymap.set("n", "<leader>qo", ":copen<CR>", { desc = "Quickfix Open" })
vim.keymap.set("n", "<leader>qc", ":cclose<CR>", { desc = "Quickfix Close" })
vim.keymap.set("n", "<leader>qn", ":cnext<CR>", { desc = "Quickfix Next" })
vim.keymap.set("n", "<leader>qp", ":cprev<CR>", { desc = "Quickfix Previous" })
vim.keymap.set("n", "<leader>qf", ":cfirst<CR>", { desc = "Quickfix First" })
vim.keymap.set("n", "<leader>ql", ":clast<CR>", { desc = "Quickfix Last" })

vim.keymap.set("n", "<leader>lr", ":LspRestart<CR>", { desc = "LSP Restart" })
vim.keymap.set("n", "<leader>li", ":LspInfo<CR>", { desc = "LSP Info" })

vim.keymap.set("n", "<leader>to", ":NvimTreeOpen<CR>", { desc = "NvimTree Open" })
vim.keymap.set("n", "<leader>tc", ":NvimTreeClose<CR>", { desc = "NvimTree Close" })
vim.keymap.set("n", "<leader>tt", ":NvimTreeToggle<CR>", { desc = "NvimTree Toggle" })
vim.keymap.set("n", "<leader>tf", ":NvimTreeFocus<CR>", { desc = "NvimTree Focus" })

vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "LSP Rename" })

vim.keymap.set("n", "<leader>mm", ":RenderMarkdown toggle<CR>", { desc = "Markdown Preview" })

vim.keymap.set("n", "<leader>frya", function()
  local char = vim.fn.input("Character to yank inside: ")
  return "yi" .. char .. ' :%s/<C-R>"//g<LEFT><LEFT>'
end, { desc = "Choose [Y]ank Character [A]ll", expr = true })
vim.keymap.set("n", "<leader>fryc", function()
  local char = vim.fn.input("Character to yank inside: ")
  return "yi" .. char .. ' :%s/<C-R>"//gc<LEFT><LEFT><LEFT>'
end, { desc = "Choose [Y]ank Character [C]onfirm", expr = true })

-- VSCode-style line movement
vim.keymap.set("n", "<A-Up>", "yyddkP", { noremap = true, silent = true })
vim.keymap.set("n", "<A-k>", "yyddkP", { noremap = true, silent = true })
vim.keymap.set("n", "<A-Down>", "yyddp", { noremap = true, silent = true })
vim.keymap.set("n", "<A-j>", "yyddp", { noremap = true, silent = true })

vim.keymap.set("n", "<AS-Up>", "yyP", { noremap = true, silent = true })
vim.keymap.set("n", "<AS-K>", "yyP", { noremap = true, silent = true })
vim.keymap.set("n", "<AS-Down>", "yyp", { noremap = true, silent = true })
vim.keymap.set("n", "<AS-J>", "yyp", { noremap = true, silent = true })

local MiniMap = require("mini.map")
vim.keymap.set("n", "<Leader>mc", MiniMap.close, { desc = "MiniMap Close" })
vim.keymap.set("n", "<Leader>mf", MiniMap.toggle_focus, { desc = "MiniMap Toggle Focus" })
vim.keymap.set("n", "<Leader>mo", MiniMap.open, { desc = "MiniMap Open" })
vim.keymap.set("n", "<Leader>mr", MiniMap.refresh, { desc = "MiniMap Refresh" })
vim.keymap.set("n", "<Leader>ms", MiniMap.toggle_side, { desc = "MiniMap Toggle Side" })
vim.keymap.set("n", "<Leader>mt", MiniMap.toggle, { desc = "MiniMap Toggle" })

vim.keymap.set("n", "<Leader>cc", ":CopilotChatToggle<CR>", { desc = "Copilot Chat Toggle" })

local function compare_to_clipboard()
  local ftype = vim.api.nvim_eval("&filetype")
  vim.cmd(string.format([[
    execute "normal! \"xy"
    vsplit
    enew
    normal! P
    setlocal buftype=nowrite
    set filetype=%s
    diffthis
    execute "normal! \<C-w>\<C-w>"
    enew
    set filetype=%s
    normal! "xP
    diffthis
  ]], ftype, ftype))
end

vim.keymap.set('x', '<Leader>cwc', compare_to_clipboard, { desc = "Compare with Clipboard" })

vim.keymap.set("n", "<leader>td", function()
  local current = vim.diagnostic.config().inline
  vim.diagnostic.config({ inline = not current })
  print("Inline diagnostics: " .. (not current and "enabled" or "disabled"))
  vim.cmd("redraw!")
end, { desc = "[T]oggle Inline [D]iagnostics" })

local editCfg = require("custom.custom")

return {
  editCfg = editCfg,
  editKevin = editCfg.editKevin,
  editPlugins = editCfg.editPlugins,
}
