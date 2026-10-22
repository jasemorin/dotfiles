-- single source of truth for which language servers we want
local servers = { "lua_ls", "pyright", "ts_ls", "bashls", "jsonls" }

return {
  {
    "williamboman/mason.nvim",
    config = true,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "mason.nvim" },
    opts = {
      ensure_installed = servers,
    },
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "mason.nvim",
      "mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", {}),
        callback = function(ev)
          local opts = { buffer = ev.buf }
          local map = vim.keymap.set
          map("n", "gd", vim.lsp.buf.definition, opts)
          map("n", "gD", vim.lsp.buf.declaration, opts)
          -- references / implementation / hover 用 0.11 自带的 grr / gri / K；
          -- 自己映射 gr 会挡住 grn、gra、grr、gri
          map("n", "<leader>rn", vim.lsp.buf.rename, opts)
          map("n", "<leader>ca", vim.lsp.buf.code_action, opts)
          -- 不用 <leader>f：它是 Telescope <leader>ff 等的前缀，停顿超过 timeoutlen 就会误格式化
          map("n", "<leader>cf", function()
            vim.lsp.buf.format({ async = true })
          end, opts)
        end,
      })

      vim.lsp.config("*", { capabilities = capabilities })

      -- bashls surfaces shellcheck diagnostics only if shellcheck is on PATH
      vim.lsp.config("bashls", {
        settings = {
          bashIde = { shellcheckPath = "shellcheck" },
        },
      })

      vim.lsp.enable(servers)
    end,
  },
}
