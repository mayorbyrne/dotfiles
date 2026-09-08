return {
	{
		"nvim-neotest/neotest",
		dependencies = {
			"nvim-neotest/nvim-nio",
			"nvim-lua/plenary.nvim",
			"antoinemadec/FixCursorHold.nvim",
			"nvim-treesitter/nvim-treesitter",
			"marilari88/neotest-vitest",
		},
		opts = {
			adapters = {
        ["neotest-vitest"] = {
          command = "vitest",
          args = { "--run", "--coverage", "--reporter", "verbose" },
          env = {
            NODE_ENV = "test",
          },
        },
			},
		},
	},
}
