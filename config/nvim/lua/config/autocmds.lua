local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

-- briefly highlight yanked text
autocmd("TextYankPost", {
  group = augroup("HighlightYank", { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- return to last cursor position when reopening a file
autocmd("BufReadPost", {
  group = augroup("LastPosition", { clear = true }),
  callback = function(ev)
    local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
    local lines = vim.api.nvim_buf_line_count(ev.buf)
    if mark[1] > 0 and mark[1] <= lines then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- shell scripts: real tabs, POSIX-ish width
autocmd("FileType", {
  group = augroup("ShellIndent", { clear = true }),
  pattern = { "sh", "bash", "zsh" },
  callback = function()
    vim.bo.shiftwidth = 4
    vim.bo.tabstop = 4
  end,
})
