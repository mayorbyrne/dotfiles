return {
  {
    "HiPhish/rainbow-delimiters.nvim",
    config = function()
      vim.api.nvim_set_hl(0, "RainbowDelimiterYellow", { fg = "#FCD400", ctermfg = "White" })
      vim.api.nvim_set_hl(0, "RainbowDelimiterRed", { fg = "#DA70D6", ctermfg = "White" })
      vim.api.nvim_set_hl(0, "RainbowDelimiterBlue", { fg = "#179DFB", ctermfg = "White" })

      -- This module contains a number of default definitions
      local rainbow_delimiters = require("rainbow-delimiters")

      -- Guard against filetypes with no treesitter parser installed
      local lib = require("rainbow-delimiters.lib")
      local original_attach = lib.attach
      lib.attach = function(bufnr, ...)
        local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
        if ok and parser then
          original_attach(bufnr, ...)
        end
      end

      -- This sets up the colorized brackets ala vscode
      vim.g.rainbow_delimiters = {
        blacklist = { "html" },
        highlight = {
          "RainbowDelimiterYellow",
          "RainbowDelimiterRed",
          "RainbowDelimiterBlue",
          -- "RainbowDelimiterOrange",
          -- "RainbowDelimiterGreen",
          -- "RainbowDelimiterViolet",
          -- "RainbowDelimiterCyan",
        },
      }
    end,
  },
}
