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
			})
		end,
	},
}
