-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- LazyVim auto format
vim.g.autoformat = false

vim.g.netrw_sort_options = "i"
vim.opt.termguicolors = true

vim.g.minimap_width = 10
vim.g.minimap_auto_start = 1
vim.g.minimap_auto_start_win_enter = 1

vim.g.softtabstop = 2
vim.g.shiftwidth = 2
vim.g.expandtab = false
vim.g.tabstop = 2

vim.cmd([[
let g:lsc_auto_map = {
    \ 'GoToDefinition': 'gdd',
    \ 'GoToDefinitionSplit': ['<C-W>]', '<C-W><C-]>'],
    \ 'FindReferences': 'gr',
    \ 'NextReference': '<C-n>',
    \ 'PreviousReference': '<C-p>',
    \ 'FindImplementations': 'gI',
    \ 'FindCodeActions': 'ga',
    \ 'Rename': 'gR',
    \ 'ShowHover': v:true,
    \ 'DocumentSymbol': 'go',
    \ 'WorkspaceSymbol': 'gS',
    \ 'SignatureHelp': 'gm',
    \ 'Completion': 'completefunc',
    \}
]])

vim.cmd([[
" From http://got-ravings.blogspot.com/2008/07/vim-pr0n-visual-search-mappings.html

" makes * and # work on visual mode too.  global function so user mappings can call it.
" specifying 'raw' for the second argument prevents escaping the result for vimgrep
" TODO: there's a bug with raw mode.  since we're using @/ to return an unescaped
" search string, vim's search highlight will be wrong.  Refactor plz.
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

" replace vim's built-in visual * and # behavior
xnoremap * :<C-u>call VisualStarSearchSet('/')<CR>/<C-R>=@/<CR><CR>
xnoremap # :<C-u>call VisualStarSearchSet('?')<CR>?<C-R>=@/<CR><CR>

" recursively vimgrep for word under cursor or selection
if maparg('<leader>*', 'n') == ''
  nnoremap <leader>* :execute 'noautocmd vimgrep /\V' . substitute(escape(expand("<cword>"), '\'), '\n', '\\n', 'g') . '/ **'<CR>
endif
if maparg('<leader>*', 'v') == ''
  vnoremap <leader>* :<C-u>call VisualStarSearchSet('/')<CR>:execute 'noautocmd vimgrep /' . @/ . '/ **'<CR>
endif

autocmd BufWritePre *.pl %s/\s\+$//e
autocmd FileType dart,js,ts,html,css,md autocmd BufWritePre <buffer> %s/\s\+$//e

]])

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
vim.g.copilot_no_tab_map = true

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

vim.cmd("ca wq bd!")
vim.cmd("ca q bd!")

vim.keymap.set("n", "<leader>kb", ':VimuxRunCommand "webdev serve"<CR>')
vim.keymap.set("n", "<leader>kg", ':VimuxRunCommand "lazygit"<CR>')
vim.keymap.set("n", "<leader>gi", ":Git<CR>", { desc = "Git Fugitive" })

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

-- local editCfg = require("custom.mac")
--
-- return {
--   editCfg = editCfg,
--   editKevin = editCfg.editKevin,
--   editPlugins = editCfg.editPlugins,
-- }
