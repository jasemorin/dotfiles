local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    -- LazyVim 本体：提供默认插件集与默认配置
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },

    -- Extras：官方维护的可选配置包（也可用 :LazyExtras 图形界面增删）
    { import = "lazyvim.plugins.extras.lang.java" },
    { import = "lazyvim.plugins.extras.lang.python" },
    { import = "lazyvim.plugins.extras.lang.markdown" },
    { import = "lazyvim.plugins.extras.lang.json" },
    { import = "lazyvim.plugins.extras.lang.typescript" },

    -- 个人覆盖：必须放在最后，才能覆盖上面的默认值
    { import = "plugins" },
  },
  install = { colorscheme = { "tokyonight" } },
  -- 没有插件需要 luarocks，关掉以免 checkhealth 报 hererocks 未安装
  rocks = { enabled = false },
  checker = { enabled = true, notify = false },
  performance = {
    rtp = {
      disabled_plugins = { "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin" },
    },
  },
})
