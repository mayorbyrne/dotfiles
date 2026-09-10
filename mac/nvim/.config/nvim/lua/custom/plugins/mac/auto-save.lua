return {
  {
    "Pocco81/auto-save.nvim",
    config = function()
      require("auto-save").setup({
        condition = function(buf)
          -- auto-save defers this check, so the buffer can be gone by now.
          if not vim.api.nvim_buf_is_valid(buf) then
            return false
          end
          if vim.bo[buf].filetype == "harpoon" then
            return false
          else
            return true -- met condition(s), can save
          end
        end,
      })
    end,
  },
}
