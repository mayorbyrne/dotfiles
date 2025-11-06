vim.g.netrw_sort_options = "i"
vim.opt.termguicolors = true

vim.g.minimap_width = 10
vim.g.minimap_auto_start = 1
vim.g.minimap_auto_start_win_enter = 1

vim.o.softtabstop = 2
vim.o.shiftwidth = 2
vim.o.expandtab = true
vim.o.tabstop = 2

vim.o.guicursor = "i:ver25,a:blinkwait60-blinkoff500-blinkon500"

vim.o.foldlevel = 20
vim.o.foldmethod = "expr"
vim.o.foldexpr = "nvim_treesitter#foldexpr()"

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
vim.keymap.set("n", "D", '"_D', {})
vim.keymap.set("n", "c", '"_c', {})
vim.keymap.set("v", "c", '"_c', {})
vim.keymap.set("n", "C", '"_C', {})
vim.keymap.set("n", "diw", '"_diw', {})
vim.keymap.set("v", "diw", '"_diw', {})
vim.keymap.set("n", "ciw", '"_ciw', {})
vim.keymap.set("v", "ciw", '"_ciw', {})

-- do not map c or d in SELECT mode
vim.keymap.set("s", "c", "c", {})
vim.keymap.set("s", "d", "d", {})

vim.keymap.set("n", "<leader>bc", ":%bd|e#<CR>", { desc = "Close all buffers except current" })

vim.keymap.set("i", "<C-J>", 'copilot#Accept("\\<CR>")', {
  expr = true,
  replace_keycodes = false,
})
vim.g.copilot_no_tab_map = true
vim.keymap.set("n", "<leader>cc", ":CopilotChatToggle<CR>", { desc = "Copilot Chat" })
vim.keymap.set("n", "<leader>cx", ":CopilotChatCommit<CR>", { desc = "Copilot Chat Commit" })

vim.keymap.set("n", "<leader>dd", ":Dashboard<CR>")
vim.keymap.set("n", "<leader>dr", ":Telescope oldfiles<CR>")
vim.keymap.set("n", "<leader>pp", ":Prettier<CR>")
-- vim.keymap.set('n', '<leader>ee', ':Telescope file_browser<CR>')

vim.keymap.set("n", "<leader>bn", ":bn<CR>")
vim.keymap.set("n", "<leader>bp", ":bp<CR>")
vim.keymap.set("t", "<leader>bd", ":bd!<CR>")
vim.keymap.set("n", "<leader>bd", function()
  if vim.bo.buftype == "terminal" then
    vim.cmd("bd!")
  else
    require("trouble").close("diagnostics")
    vim.cmd("bd")
  end
end)

vim.cmd("ca wq bd!")
vim.cmd("ca q bd!")

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

vim.keymap.set("n", "<leader>lr", function()
  -- Get all buffers and their attached clients before restart
  local buf_clients = {}
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      local clients = vim.lsp.get_clients({ bufnr = bufnr })
      if #clients > 0 then
        buf_clients[bufnr] = {}
        for _, client in ipairs(clients) do
          table.insert(buf_clients[bufnr], client.name)
        end
      end
    end
  end
  
  -- Stop all LSP clients
  vim.lsp.stop_client(vim.lsp.get_clients())
  
  -- Wait for clients to stop and restart
  vim.defer_fn(function()
    -- Trigger LSP start on all buffers that had clients
    for bufnr, _ in pairs(buf_clients) do
      if vim.api.nvim_buf_is_loaded(bufnr) then
        local ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
        vim.api.nvim_set_option_value("filetype", ft, { buf = bufnr })
      end
    end
  end, 100)
end, { desc = "LSP Restart" })
vim.keymap.set("n", "<leader>li", ":LspInfo<CR>", { desc = "LSP Info" })

vim.keymap.set("n", "<leader>to", ":NvimTreeOpen<CR>", { desc = "NvimTree Open" })
vim.keymap.set("n", "<leader>tc", ":NvimTreeClose<CR>", { desc = "NvimTree Close" })
vim.keymap.set("n", "<leader>tt", ":NvimTreeToggle<CR>", { desc = "NvimTree Toggle" })
vim.keymap.set("n", "<leader>tf", ":NvimTreeFocus<CR>", { desc = "NvimTree Focus" })

vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "LSP Rename" })

vim.keymap.set("n", "<leader>m", ":RenderMarkdown toggle<CR>", { desc = "Markdown Preview" })

vim.keymap.set("n", "<leader>frya", function()
  local char = vim.fn.input("Character to yank inside: ")
  return "yi" .. char .. ' :%s/<C-R>"//g<LEFT><LEFT>'
end, { desc = "Choose [Y]ank Character [A]ll", expr = true })
vim.keymap.set("n", "<leader>fryc", function()
  local char = vim.fn.input("Character to yank inside: ")
  return "yi" .. char .. ' :%s/<C-R>"//gc<LEFT><LEFT><LEFT>'
end, { desc = "Choose [Y]ank Character [C]onfirm", expr = true })

-- VSCode style keybindings for moving lines up / down
-- We can use the keyboard shortcut Option + Up/Down (on Macs) or Alt + Up/Down (on Windows) to move lines up and down. We can use the keyboard shortcut Shift + Option + Up/Down (on Macs) or Shift + Alt + Up/Down (on Windows) to duplicate lines above or below the current line.
vim.keymap.set("n", "<A-Up>", "yyddkP", { noremap = true, silent = true })
vim.keymap.set("n", "<A-k>", "yyddkP", { noremap = true, silent = true })
vim.keymap.set("n", "<A-Down>", "yyddp", { noremap = true, silent = true })
vim.keymap.set("n", "<A-j>", "yyddp", { noremap = true, silent = true })

vim.keymap.set("n", "<AS-Up>", "yyP", { noremap = true, silent = true })
vim.keymap.set("n", "<AS-K>", "yyP", { noremap = true, silent = true })
vim.keymap.set("n", "<AS-Down>", "yyp", { noremap = true, silent = true })
vim.keymap.set("n", "<AS-J>", "yyp", { noremap = true, silent = true })

vim.keymap.set("v", "<leader>yy", function()
  -- yank selection to a temporary register
  vim.cmd('normal! "ty')
  -- append a newline and the contents of the temporary register to register a
  local to_append = "\n" .. vim.fn.getreg("t")
  vim.fn.setreg("a", vim.fn.getreg("a") .. to_append)
end, { desc = "Yank and append with newline to register a", silent = true })

vim.keymap.set("n", "<leader>pp", '"ap', { desc = "Paste from register a" })

-- prevent fat fingering multiple undos
vim.keymap.set("n", "u", function()
  if vim.v.count > 0 then
    -- clear the count by sending ESC to neovim
    local keys = vim.api.nvim_replace_termcodes("<ESC>", true, false, true)
    vim.api.nvim_feedkeys(keys, "m", false)

    local message = "You fat fingered "
        .. vim.v.count
        .. " undos. Preventing this action, and resetting your vim count."

    vim.notify(message, vim.log.levels.WARN)

    -- do nothing
    return ""
  else
    return "u"
  end
end, { expr = true })

vim.keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, { desc = "LSP Signature Help" })
vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, { desc = "LSP Signature Help" })

vim.keymap.set("n", "<leader>rt", function ()
  require("neotest").run.run()
  end, { desc = "Run Neotest" })

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

vim.keymap.set('x', '<Leader>d', compare_to_clipboard, { desc = "Compare to Clipboard" })

local editCfg = require("custom.custom")

return {
  editCfg = editCfg,
  editKevin = editCfg.editKevin,
  editPlugins = editCfg.editPlugins,
}
