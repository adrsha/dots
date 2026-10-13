return {
  {
    "yousefhadder/markdown-plus.nvim",
    lazy = false,
    ft = "markdown",
    opts = {},
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    lazy = false,
    ft = "markdown",
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
    opts = {},
  },
}
