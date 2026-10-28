-- 笔记库路径按机器不同：只保留实际存在的；一个都没有（比如没同步 iCloud 的 Linux）就不加载插件，
-- 否则 obsidian.nvim 每次打开 markdown 都报「At least one workspace is required」
-- 新机器上的笔记库位置不同，往这里加一行即可
local candidates = {
  { name = "uni", path = "~/Library/Mobile Documents/com~apple~CloudDocs/University/Obsidian Vaults" }, -- macOS iCloud
}

local workspaces = vim.tbl_filter(function(ws)
  return vim.fn.isdirectory(vim.fn.expand(ws.path)) == 1
end, candidates)

return {
  "obsidian-nvim/obsidian.nvim",
  ft = "markdown",
  cond = #workspaces > 0,
  opts = {
    legacy_commands = false,
    workspaces = workspaces,
    -- 渲染交给 render-markdown.nvim（LazyVim 的 lang.markdown 自带），
    -- 两者同时开会冲突，:checkhealth 会直接报 ERROR
    ui = { enable = false },
    -- 补全由 obsidian.nvim 内置的 obsidian-ls 提供，不再需要 completion 设置
  },
}
