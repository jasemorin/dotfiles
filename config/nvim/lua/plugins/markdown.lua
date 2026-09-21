-- Markdown 写作增强。
-- 渲染本身由 LazyVim 的 lang.markdown extra 提供（render-markdown.nvim），
-- 这里只补 extra 没有的部分：浏览器预览、表格自动对齐、写作时的软换行。

return {
  -- 浏览器实时预览：:MarkdownPreviewToggle 或 <leader>mp
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = function()
      vim.fn["mkdp#util#install"]()
    end,
    keys = {
      {
        "<leader>mp",
        "<cmd>MarkdownPreviewToggle<cr>",
        ft = "markdown",
        desc = "Markdown Preview (browser)",
      },
    },
  },

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
