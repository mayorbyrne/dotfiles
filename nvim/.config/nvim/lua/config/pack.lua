local gh = function(repo)
  return "https://github.com/" .. repo
end

local specs = {
  gh("folke/tokyonight.nvim"),
  gh("askfiy/visual_studio_code"),
  gh("nvim-lua/plenary.nvim"),
  gh("nvim-tree/nvim-web-devicons"),
  gh("folke/which-key.nvim"),
  gh("numToStr/Comment.nvim"),
  gh("lewis6991/gitsigns.nvim"),
  gh("folke/trouble.nvim"),
  gh("folke/todo-comments.nvim"),
  gh("stevearc/oil.nvim"),
  gh("nvimtools/none-ls.nvim"),
  gh("windwp/nvim-autopairs"),
  gh("echasnovski/mini.nvim"),
  gh("nvim-telescope/telescope.nvim"),
  gh("nvim-treesitter/nvim-treesitter"),
  gh("neovim/nvim-lspconfig"),
  gh("mason-org/mason.nvim"),
  gh("mason-org/mason-lspconfig.nvim"),
  gh("hrsh7th/nvim-cmp"),
  gh("hrsh7th/cmp-nvim-lsp"),
  gh("hrsh7th/cmp-buffer"),
  gh("hrsh7th/cmp-path"),
  gh("saadparwaiz1/cmp_luasnip"),
  gh("L3MON4D3/LuaSnip"),
  gh("rafamadriz/friendly-snippets"),
  gh("j-hui/fidget.nvim"),
  gh("github/copilot.vim"),
  gh("tpope/vim-fugitive"),
  gh("nvim-neotest/neotest"),
  gh("nvim-neotest/nvim-nio"),
  gh("marilari88/neotest-vitest"),
  gh("MeanderingProgrammer/render-markdown.nvim"),
}

vim.pack.add(specs, {
  load = function(plugin)
    vim.cmd.packadd(plugin.spec.name)
  end,
  confirm = false,
})
