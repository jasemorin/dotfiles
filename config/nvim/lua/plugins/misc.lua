return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {},
  },
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = {},
  },
  {
    "numToStr/Comment.nvim",
    keys = { "gc", "gcc", "gb", "gbc" },
    opts = {},
  },
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup({})
      -- teach cmp's <CR> to add () after confirming a function completion
      local ok, cmp = pcall(require, "cmp")
      if ok then
        cmp.event:on(
          "confirm_done",
          require("nvim-autopairs.completion.cmp").on_confirm_done()
        )
      end
    end,
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = { "BufReadPost", "BufNewFile" },
    opts = {},
  },
  {
    "nvim-tree/nvim-web-devicons",
    lazy = true,
  },
}
