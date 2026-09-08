return {
  {
    "github/copilot.vim",
    version = "1.41.0"
  },
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    dependencies = {
      { "github/copilot.vim" },    -- or zbirenbaum/copilot.lua
      { "nvim-lua/plenary.nvim" }, -- for curl, log wrapper
    },
    build = "make tiktoken",       -- Only on MacOS or Linux
    opts = {
      debug = true,                -- Enable debug mode
      prompts = {
        Commit = {
          prompt = [[
#git:staged

Write a Git commit message for the staged changes using the Conventional Commits specification. Follow these rules:
- The title (subject) must start with a valid type (e.g., `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`, etc.), followed by a brief summary of the change.
- The title must be a maximum of 50 characters.
- The body must use bullet points to describe the changes. Each bullet point should:
  - Start with a `-` followed by a space.
  - Clearly explain a specific change or reason for the change.
  - Be wrapped at 72 characters per line.
- If the changes include breaking changes, add a `BREAKING CHANGE:` section describing the impact.
- If applicable, include references to issues or pull requests.

Wrap the entire commit message in a code block with the language `gitcommit`.
]],
        },
      },
    },
  },
}
