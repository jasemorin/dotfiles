-- 只保留 LazyVim 没有提供的映射。
-- 已由 LazyVim 提供、因此删除的：<Esc> 清高亮、<C-hjkl> 窗口跳转、[d/]d 诊断跳转。
-- 注意：<leader>e 被 LazyVim 用作文件树，行内诊断改用 <leader>cd。

local map = vim.keymap.set

-- 可视模式上下移动选中行（LazyVim 用的是 <A-j>/<A-k>，两者不冲突）
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- 翻页后把光标保持在屏幕中间
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")

-- 快速退出插入模式
map("i", "jj", "<Esc>", { desc = "Exit insert mode" })
map("i", "kk", "<Esc>", { desc = "Exit insert mode" })
