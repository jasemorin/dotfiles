-- vault 在 Mac 的 iCloud 里。Linux 上没有这个目录：obsidian.nvim 遇到不存在的
-- workspace 会在打开 markdown 时报错，所以目录不在就整个不加载
local vault = vim.fn.expand("~/Library/Mobile Documents/com~apple~CloudDocs/University/Obsidian Vaults")

return {
  "obsidian-nvim/obsidian.nvim",
  ft = "markdown",
  cond = vim.fn.isdirectory(vault) == 1,
  opts = {
    legacy_commands = false,
    workspaces = {
      { name = "uni", path = vault },
    },
    -- 渲染交给 render-markdown.nvim（LazyVim 的 lang.markdown 自带），
    -- 两者同时开会冲突，:checkhealth 会直接报 ERROR
    ui = { enable = false },
    completion = { nvim_cmp = false, blink = true },
  },
}
