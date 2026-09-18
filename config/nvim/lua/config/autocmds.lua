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
