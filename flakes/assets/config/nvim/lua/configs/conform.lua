local options = {
  formatters_by_ft = {
    astro = { lsp_format = "fallback" },
    lua = { "stylua" },
    css = { "prettierd" },
    html = { "prettierd" },
    python = { "black" },
    rust = { "rustfmt", lsp_format = "fallback" },
    javascript = { lsp_format = "fallback" },
    typescript = { lsp_format = "fallback" },
  },

  formatters = {
    stylua = {},

    prettierd = {},

    black = {},

    rustfmt = {
      prepend_args = {
        "--config",
        "tab_spaces=4,hard_tabs=false",
      },
    },
  },
}

return options
