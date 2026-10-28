-- LazyVim 已自带：yank 高亮、恢复上次光标位置、关闭某些 buffer 的 q 键等。
-- 这里只保留个人特有的规则。

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("ShellIndent", { clear = true }),
  pattern = { "sh", "bash", "zsh" },
  callback = function()
    vim.bo.shiftwidth = 4
    vim.bo.tabstop = 4
  end,
})

-- Markdown 写作模式：软换行按单词断行，j/k 按视觉行移动，关闭行号干扰
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("MarkdownWriting", { clear = true }),
  pattern = { "markdown" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true -- 在单词边界断行，不会把词切断
    vim.opt_local.spell = true
    vim.opt_local.spelllang = "en_au"
    vim.keymap.set({ "n", "v" }, "j", "gj", { buffer = true })
    vim.keymap.set({ "n", "v" }, "k", "gk", { buffer = true })
  end,
})
