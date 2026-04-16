local map = vim.keymap.set
local telescope_builtin = require("telescope.builtin")
local trouble = require("trouble")
local neotest = require("neotest")

map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

map("n", "<left>", '<cmd>echo "Use h to move!!"<CR>')
map("n", "<right>", '<cmd>echo "Use l to move!!"<CR>')
map("n", "<up>", '<cmd>echo "Use k to move!!"<CR>')
map("n", "<down>", '<cmd>echo "Use j to move!!"<CR>')

map("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus left" })
map("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus down" })
map("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus up" })
map("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus right" })

map("n", "d", '"_d')
map("v", "d", '"_d')
map("n", "D", '"_D')
map("n", "c", '"_c')
map("v", "c", '"_c')
map("n", "C", '"_C')
map("n", "diw", '"_diw')
map("v", "diw", '"_diw')
map("n", "ciw", '"_ciw')
map("v", "ciw", '"_ciw')
map("s", "c", "c")
map("s", "d", "d")

local function close_other_buffers()
  local current = vim.api.nvim_get_current_buf()
  for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
    if buffer ~= current and vim.bo[buffer].buflisted then
      vim.api.nvim_buf_delete(buffer, { force = false })
    end
  end
end

local function close_current_buffer()
  if vim.bo.buftype == "terminal" then
    vim.cmd("bd!")
    return
  end

  trouble.close()
  vim.cmd("bd")
end

local function compare_to_clipboard()
  local selection = table.concat(vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos(".")), "\n")
  local clipboard = vim.fn.getreg("+")
  local filetype = vim.bo.filetype

  vim.cmd("vsplit")
  vim.cmd("enew")
  vim.bo.buftype = "nofile"
  vim.bo.bufhidden = "wipe"
  vim.bo.swapfile = false
  vim.bo.filetype = filetype
  vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(clipboard, "\n", { plain = true }))
  vim.cmd("diffthis")

  vim.cmd("wincmd p")
  vim.cmd("enew")
  vim.bo.buftype = "nofile"
  vim.bo.bufhidden = "wipe"
  vim.bo.swapfile = false
  vim.bo.filetype = filetype
  vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(selection, "\n", { plain = true }))
  vim.cmd("diffthis")
end

local function format_code()
  vim.lsp.buf.format({
    async = true,
    filter = function(client)
      return client.name ~= "ts_ls"
        and client.name ~= "eslint"
        and client.name ~= "volar"
        and client.name ~= "html"
        and client.name ~= "cssls"
    end,
  })
end

map("n", "<leader>bc", close_other_buffers, { desc = "Close other buffers" })
map("n", "<leader>bn", "<cmd>bn<CR>", { desc = "Next buffer" })
map("n", "<leader>bp", "<cmd>bp<CR>", { desc = "Previous buffer" })
map("n", "<leader>bd", close_current_buffer, { desc = "Close buffer" })

vim.cmd("cabbrev wq bd!")
vim.cmd("cabbrev q bd!")

map("n", "<leader>sh", telescope_builtin.help_tags, { desc = "[S]earch [H]elp" })
map("n", "<leader>sk", telescope_builtin.keymaps, { desc = "[S]earch [K]eymaps" })
map("n", "<leader>sf", telescope_builtin.find_files, { desc = "[S]earch [F]iles" })
map("n", "<leader>ss", telescope_builtin.buffers, { desc = "[S]earch [S]elect Buffers" })
map("n", "<leader>sw", telescope_builtin.grep_string, { desc = "[S]earch current [W]ord" })
map("n", "<leader>sg", telescope_builtin.live_grep, { desc = "[S]earch by [G]rep" })
map("n", "<leader>sd", telescope_builtin.diagnostics, { desc = "[S]earch [D]iagnostics" })
map("n", "<leader>sr", telescope_builtin.resume, { desc = "[S]earch [R]esume" })
map("n", "<leader>s.", telescope_builtin.oldfiles, { desc = '[S]earch recent files' })
map("n", "<leader><leader>", telescope_builtin.buffers, { desc = "Find existing buffers" })
map("n", "<leader>sn", function()
  telescope_builtin.find_files({ cwd = vim.fn.stdpath("config") })
end, { desc = "[S]earch [N]eovim files" })

map("n", "<leader>cf", format_code, { desc = "[C]ode [F]ormat" })
map("n", "<leader>pp", format_code, { desc = "Format file" })

map("i", "<C-j>", 'copilot#Accept("\\<CR>")', {
  expr = true,
  replace_keycodes = false,
  desc = "Accept Copilot suggestion",
})

map("n", "<leader>gi", "<cmd>Git<CR>", { desc = "[G]it" })
map("n", "<leader>e", function()
  vim.diagnostic.open_float(0, { scope = "line" })
end, { desc = "Line diagnostics" })

map("n", "<leader>xx", "<cmd>Trouble diagnostics toggle focus=true<CR>", { desc = "Diagnostics list" })
map("n", "<leader>xc", "<cmd>Trouble diagnostics close<CR>", { desc = "Close diagnostics" })
map("n", "<leader>xn", function()
  trouble.next({ skip_groups = true, jump = true })
end, { desc = "Next diagnostic" })
map("n", "<leader>xp", function()
  trouble.previous({ skip_groups = true, jump = true })
end, { desc = "Previous diagnostic" })

map("n", "<leader>qq", "<cmd>copen<CR>", { desc = "Open quickfix" })
map("n", "<leader>qo", "<cmd>copen<CR>", { desc = "Open quickfix" })
map("n", "<leader>qc", "<cmd>cclose<CR>", { desc = "Close quickfix" })
map("n", "<leader>qn", "<cmd>cnext<CR>", { desc = "Next quickfix item" })
map("n", "<leader>qp", "<cmd>cprev<CR>", { desc = "Previous quickfix item" })
map("n", "<leader>qf", "<cmd>cfirst<CR>", { desc = "First quickfix item" })
map("n", "<leader>ql", "<cmd>clast<CR>", { desc = "Last quickfix item" })

map("n", "-", "<cmd>Oil<CR>", { desc = "Open parent directory" })
map("n", "<leader>tt", "<cmd>Oil --float<CR>", { desc = "Toggle explorer" })
map("n", "<leader>tf", "<cmd>Oil<CR>", { desc = "Focus explorer" })

map("n", "<leader>m", "<cmd>RenderMarkdown toggle<CR>", { desc = "Markdown preview" })

map("n", "<A-Up>", "yyddkP", { noremap = true, silent = true, desc = "Move line up" })
map("n", "<A-k>", "yyddkP", { noremap = true, silent = true, desc = "Move line up" })
map("n", "<A-Down>", "yyddp", { noremap = true, silent = true, desc = "Move line down" })
map("n", "<A-j>", "yyddp", { noremap = true, silent = true, desc = "Move line down" })
map("n", "<S-A-Up>", "yyP", { noremap = true, silent = true, desc = "Duplicate line up" })
map("n", "<S-A-k>", "yyP", { noremap = true, silent = true, desc = "Duplicate line up" })
map("n", "<S-A-Down>", "yyp", { noremap = true, silent = true, desc = "Duplicate line down" })
map("n", "<S-A-j>", "yyp", { noremap = true, silent = true, desc = "Duplicate line down" })

map("v", "<leader>yy", function()
  vim.cmd('normal! "ty')
  local to_append = "\n" .. vim.fn.getreg("t")
  vim.fn.setreg("a", vim.fn.getreg("a") .. to_append)
end, { desc = "Append selection to register a", silent = true })
map("n", "<leader>pa", '"ap', { desc = "Paste register a" })

map("n", "u", function()
  if vim.v.count > 0 then
    local keys = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
    vim.api.nvim_feedkeys(keys, "m", false)
    vim.notify(
      "You fat fingered " .. vim.v.count .. " undos. Resetting the count instead.",
      vim.log.levels.WARN
    )
    return ""
  end
  return "u"
end, { expr = true, desc = "Undo safely" })

map("i", "<C-k>", vim.lsp.buf.signature_help, { desc = "Signature help" })
map("n", "<leader>rt", function()
  neotest.run.run()
end, { desc = "Run nearest test" })
map("v", "<leader>d", compare_to_clipboard, { desc = "Compare selection to clipboard" })
