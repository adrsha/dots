return {
  "neovim/nvim-lspconfig",
  dependencies = {
    'hrsh7th/nvim-cmp',
    'hrsh7th/cmp-nvim-lsp'
  },
  config = function()
    -- Setup language servers.
    local lspconfig = require('lspconfig')

    capabilities = require 'cmp_nvim_lsp'.default_capabilities();

    lspconfig.clangd.setup {
      capabilities = capabilities

    } -- Lua
    lspconfig.lua_ls.setup {
      capabilities = capabilities
    }
  end
}
