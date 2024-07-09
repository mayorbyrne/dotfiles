return {
  {
    'Pocco81/auto-save.nvim',
    config = function()
      require('auto-save').setup {
        condition = function(buf)
          if vim.bo[buf].filetype == 'harpoon' then
            return false
          else
            return true -- met condition(s), can save
          end
        end,
      }
    end,
  },
}
