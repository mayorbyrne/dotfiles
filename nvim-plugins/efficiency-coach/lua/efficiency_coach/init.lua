local M = {}

-- Default configuration
M.config = {
  auto_suggest_on_save = false,
  auto_suggest_delay = 800, -- ms
}

local last_autosuggest = 0

local function merge(a, b)
  if not b then return a end
  for k, v in pairs(b) do a[k] = v end
  return a
end

function M.setup(opts)
  M.config = merge(M.config, opts or {})

  vim.api.nvim_create_user_command('EfficiencyCoachSuggest', function() require('efficiency_coach').suggest() end, {})
  vim.api.nvim_create_user_command('EfficiencyCoachPractice', function() require('efficiency_coach').practice() end, {})

  if M.config.auto_suggest_on_save then
    vim.api.nvim_create_autocmd('BufWritePost', {
      pattern = '*',
      callback = function(args)
        local now = vim.loop.now()
        if now - last_autosuggest < (M.config.auto_suggest_delay or 800) then return end
        last_autosuggest = now
        -- run suggest shortly after save so other autocommands finish
        vim.defer_fn(function() pcall(M.suggest) end, 50)
      end,
    })
  end
end

-- Simple heuristics that return suggestion-like tables
function M.heuristics(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local suggestions = {}

  -- long lines
  local long_count = 0
  for _, l in ipairs(lines) do if #l > 120 then long_count = long_count + 1 end end
  if long_count > 3 then
    table.insert(suggestions, {
      title = string.format('Many long lines (%d). Consider wrapping or extracting.', long_count),
      description = 'Lines exceeding 120 chars can be made more readable by wrapping or extracting logic.',
      kind = 'heuristic',
      callback = function() M.practice(bufnr) end,
    })
  end

  -- TODOs
  local todo_count = 0
  for _, l in ipairs(lines) do if l:match('%f[%w]TODO%f[%W]') then todo_count = todo_count + 1 end end
  if todo_count >= 2 then
    table.insert(suggestions, {
      title = string.format('Found %d TODO comments. Consider addressing or creating focused tasks.', todo_count),
      description = 'Multiple TODOs may indicate unfinished work; practice extracting tasks or adding tests.',
      kind = 'heuristic',
      callback = function() M.practice(bufnr) end,
    })
  end

  -- crude function-length detection
  local in_func = false
  local func_start = 0
  for idx, l in ipairs(lines) do
    if l:match('%f[%w]function%f[%W]') or l:match('%f[%w]def%f[%W]') then
      in_func = true
      func_start = idx
    elseif in_func and l:match('^%s*end%s*$') then
      local len = idx - func_start
      if len > 80 then
        table.insert(suggestions, {
          title = string.format('Function from %d to %d is long (%d lines). Consider extracting.', func_start, idx, len),
          description = 'Long functions are good candidates for extraction to improve readability and testability.',
          kind = 'heuristic',
          callback = function() M.practice(bufnr) end,
        })
      end
      in_func = false
    end
  end

  return suggestions
end

-- Combine LSP code actions + heuristics and present to the user
function M.suggest()
  local bufnr = vim.api.nvim_get_current_buf()
  local params = vim.lsp.util.make_range_params()
  local gathered = {}

  -- request LSP actions asynchronously
  vim.lsp.buf_request(bufnr, 'textDocument/codeAction', params, function(err, res)
    if err then vim.notify('Error fetching LSP suggestions: '..tostring(err), vim.log.levels.ERROR); return end

    if res and not vim.tbl_isempty(res) then
      for _, action in ipairs(res) do
        table.insert(gathered, { title = action.title, lsp = action })
      end
    end

    -- append heuristics
    local hs = M.heuristics(bufnr)
    for _, h in ipairs(hs) do table.insert(gathered, h) end

    if vim.tbl_isempty(gathered) then
      vim.notify('No efficiency suggestions available', vim.log.levels.INFO)
      return
    end

    local items = {}
    for i, it in ipairs(gathered) do items[i] = it.title end
    vim.ui.select(items, {prompt = 'Efficiency suggestions:'}, function(choice, idx)
      if not choice then return end
      local sel = gathered[idx]
      if sel.lsp then
        local action = sel.lsp
        if action.edit then vim.lsp.util.apply_workspace_edit(action.edit, 'utf-8') end
        if action.command then vim.lsp.buf.execute_command(action.command) end
        vim.notify('Applied LSP suggestion: '..action.title, vim.log.levels.INFO)
        return
      end

      if sel.kind == 'heuristic' then
        -- show description and offer to practice
        local opts = { 'Open practice buffer', 'Dismiss' }
        vim.ui.select(opts, {prompt = sel.title .. '\n\n' .. (sel.description or '')}, function(c)
          if c == 'Open practice buffer' then
            pcall(sel.callback)
          end
        end)
      end
    end)
  end)
end

-- Open a floating practice buffer containing the target buffer's contents
-- Passing bufnr will practice that buffer; otherwise current buffer
function M.practice(target_bufnr)
  local orig_buf = target_bufnr or vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(orig_buf, 0, -1, false)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  local ft = vim.api.nvim_buf_get_option(orig_buf, 'filetype')
  vim.api.nvim_buf_set_option(buf, 'filetype', ft)

  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.6)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor', width = width, height = height, row = row, col = col,
    style = 'minimal', border = 'single'
  })

  -- map apply and close
  pcall(function()
    vim.api.nvim_buf_set_keymap(buf, 'n', '<leader>a', string.format(":lua require('efficiency_coach')._apply(%d, %d)<CR>", orig_buf, buf), {nowait=true, noremap=true, silent=true})
    vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', '<Cmd>bd!<CR>', {nowait=true, noremap=true, silent=true})
  end)

  vim.notify('Practice mode: edit here. Press <leader>a to apply edits to original buffer, Esc to close', vim.log.levels.INFO)
end

function M._apply(orig_bufnr, practice_bufnr)
  if not vim.api.nvim_buf_is_valid(orig_bufnr) then
    vim.notify('Original buffer is no longer valid', vim.log.levels.ERROR)
    return
  end
  if not vim.api.nvim_buf_is_valid(practice_bufnr) then
    vim.notify('Practice buffer is no longer valid', vim.log.levels.ERROR)
    return
  end
  local lines = vim.api.nvim_buf_get_lines(practice_bufnr, 0, -1, false)
  vim.api.nvim_buf_set_lines(orig_bufnr, 0, -1, false, lines)
  vim.api.nvim_buf_delete(practice_bufnr, {force=true})
  vim.notify('Applied practice edits to original buffer', vim.log.levels.INFO)
end

return M
