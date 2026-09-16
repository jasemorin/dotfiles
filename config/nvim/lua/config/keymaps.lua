local map = vim.keymap.set

-- clear search highlight
map("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- easier window navigation
map("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to left window" })
map("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to right window" })
map("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to lower window" })
map("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to upper window" })

-- move selected lines up/down
map("v", "J", ":m '>+1<CR>gv=gv")
map("v", "K", ":m '<-2<CR>gv=gv")

-- keep cursor centered
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")

-- diagnostics
map("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
map("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic" })

-- escape to normal mode
map("i", "jj", "<Esc>", { desc = "Exit insert mode" })
map("i", "kk", "<Esc>", { desc = "Exit insert mode" })
map("i", "ll", "<Esc>", { desc = "Exit insert mode" })
