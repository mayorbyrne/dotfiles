return {
	{
		"airblade/vim-rooter",
		config = function()
			vim.g.rooter_patterns =
				{ ".git", ".gitignore", ".gitmodules", "pubspec.yaml", "package.json", "CHANGELOG.md" }
		end,
	},
}
