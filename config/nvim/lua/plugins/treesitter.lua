local ensure_installed = {
  "lua", "vim", "vimdoc", "bash", "python", "javascript",
  "typescript", "tsx", "json", "yaml", "markdown", "markdown_inline",
  "html", "css", "go", "rust",
}

-- FileType 匹配的是 filetype 而不是解析器名（bash -> sh、tsx -> typescriptreact）
local filetypes = {}
for _, lang in ipairs(ensure_installed) do
  vim.list_extend(filetypes, vim.treesitter.language.get_filetypes(lang))
end

return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  build = ":TSUpdate",
  lazy = false,
  config = function()
    require("nvim-treesitter").install(ensure_installed)

    vim.api.nvim_create_autocmd("FileType", {
      pattern = filetypes,
      callback = function()
        -- 首次启动时解析器还在异步安装，start 会报错
        if not pcall(vim.treesitter.start) then
          return
        end
        vim.wo[0][0].foldmethod = "expr"
        vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })
  end,
}
