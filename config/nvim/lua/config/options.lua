-- 只写与 LazyVim 默认值不同、或 LazyVim 没有设置的项。
-- LazyVim 的完整默认值见 :h lazyvim-options，或 `:e $LAZYVIM_ROOT/lua/lazyvim/config/options.lua`

vim.g.mapleader = " "
vim.g.maplocalleader = " " -- LazyVim 默认是 "\\"；若觉得 localleader 映射有延迟可改回

-- 补全引擎：LazyVim 默认 blink.cmp；想换回旧的 nvim-cmp 取消下面这行注释
-- vim.g.lazyvim_cmp = "nvim-cmp"

-- 选择器：LazyVim 默认 fzf-lua；想用 telescope 取消注释并启用 editor.telescope extra
-- vim.g.lazyvim_picker = "telescope"

local o = vim.opt

o.scrolloff = 8 -- LazyVim 默认 4
o.breakindent = true
o.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
o.conceallevel = 2 -- markdown 里隐藏 ** 、[[ ]] 等标记

-- 用不到的语言 provider，关掉以消除 :checkhealth 噪音
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_python3_provider = 0
