-- LazyVim 负责 mason / lspconfig / capabilities / LSP 键位。
-- lua_ls、basedpyright+ruff、jdtls、marksman、jsonls、ts_ls 均由 LazyVim 及 extras 提供。
-- 这里只补 LazyVim 没有开的 server 和个人化设置。
return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      -- bashls 只有在 PATH 上找得到 shellcheck 时才会给出 lint 诊断
      bashls = {
        settings = { bashIde = { shellcheckPath = "shellcheck" } },
      },
    },
  },
}
