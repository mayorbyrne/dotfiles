return {
  {
    "folke/trouble.nvim",
    config = function()
      require("trouble").setup({
        modes = {
          diagnostics = {
            focus = true,
          },
        },
        win = {
          wo = {
            wrap = true,
          },
        },
      })
    end,
  },
}
