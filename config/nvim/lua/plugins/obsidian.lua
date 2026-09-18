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
    -- 渲染交给 render-markdown.nvim（LazyVim 的 lang.markdown 自带），
    -- 两者同时开会冲突，:checkhealth 会直接报 ERROR
    ui = { enable = false },
    completion = { nvim_cmp = false, blink = true },
  },
}
