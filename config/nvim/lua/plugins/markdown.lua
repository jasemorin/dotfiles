-- Markdown 写作增强。
-- 渲染（render-markdown.nvim）和浏览器预览（markdown-preview.nvim，<leader>cp）
-- 都由 LazyVim 的 lang.markdown extra 提供，这里只补 extra 没有的表格自动对齐。
-- 写作时的软换行见 config/autocmds.lua。

return {
  -- 表格自动对齐：插入模式下打 | 会自动补齐列宽
  {
    "dhruvasagar/vim-table-mode",
    ft = { "markdown" },
    keys = {
      { "<leader>mt", "<cmd>TableModeToggle<cr>", ft = "markdown", desc = "Toggle Table Mode" },
    },
    config = function()
      vim.g.table_mode_corner = "|" -- 用标准 markdown 的表格分隔符
    end,
  },
}
