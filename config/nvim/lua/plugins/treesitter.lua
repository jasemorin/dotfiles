local ensure_installed = {
  "lua", "vim", "vimdoc", "bash", "python", "javascript",
  "typescript", "tsx", "json", "yaml", "markdown", "markdown_inline",
  "html", "css", "go", "rust",
}

return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  build = ":TSUpdate",
  lazy = false,
  config = function()
    require("nvim-treesitter").install(ensure_installed)

    vim.api.nvim_create_autocmd("FileType", {
      pattern = ensure_installed,
      callback = function()
        vim.treesitter.start()
        vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })
  end,
}
