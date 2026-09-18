return {
  "obsidian-nvim/obsidian.nvim",
  ft = "markdown",
  opts = {
    legacy_commands = false,
    workspaces = {
      {
        name = "uni",
        path = vim.fn.expand("~/Library/Mobile Documents/com~apple~CloudDocs/University/Obsidian Vaults"),
      },
    },
    completion = { nvim_cmp = false, blink = true },
  },
}
