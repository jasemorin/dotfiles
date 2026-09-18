-- LazyVim 自己管理 treesitter 的版本与安装；各语言 extra 也会自动补齐 parser。
-- 这里只追加 extra 没覆盖到的语言。
return {
  "nvim-treesitter/nvim-treesitter",
  opts = { ensure_installed = { "go", "rust", "html", "css" } },
}
