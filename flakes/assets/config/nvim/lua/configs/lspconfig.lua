local M = {}
local map = vim.keymap.set

-- export on_attach & capabilities
M.on_attach = function(_, bufnr)
  local function opts(desc)
    return { buffer = bufnr, desc = "LSP " .. desc }
  end
end

-- disable semanticTokens
-- M.on_init = function(client, _)
--     if vim.fn.has "nvim-0.11" ~= 1 then
--         if client.supports_method "textDocument/semanticTokens" then
--             client.server_capabilities.semanticTokensProvider = nil
--         end
--     else
--         if client:supports_method "textDocument/semanticTokens" then
--             client.server_capabilities.semanticTokensProvider = nil
--         end
--     end
-- end

M.capabilities = vim.lsp.protocol.make_client_capabilities()

M.capabilities.textDocument.completion.completionItem = {
  documentationFormat = { "markdown", "plaintext" },
  snippetSupport = true,
  preselectSupport = true,
  insertReplaceSupport = true,
  labelDetailsSupport = true,
  deprecatedSupport = true,
  commitCharactersSupport = true,
  tagSupport = { valueSet = { 1 } },
  resolveSupport = {
    properties = {
      "documentation",
      "detail",
      "additionalTextEdits",
    },
  },
}

M.defaults = function()
  dofile(vim.g.base46_cache .. "lsp")
  local x = vim.diagnostic.severity

  vim.diagnostic.config {
    -- virtual_text = { prefix = "" },
    virtual_text = false,
    signs = false,
    underline = true,
    float = { border = "single" },
  }

  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      M.on_attach(_, args.buf)
    end,
  })

  local lua_lsp_settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      workspace = {
        library = {
          vim.fn.expand "$VIMRUNTIME/lua",
          vim.fn.stdpath "data" .. "/lazy/ui/nvchad_types",
          vim.fn.stdpath "data" .. "/lazy/lazy.nvim/lua/lazy",
          "${3rd}/luv/library",
        },
      },
    },
  }

  -- Use new vim.lsp.config API for Neovim 0.11+
  vim.lsp.config("*", { capabilities = M.capabilities, on_init = M.on_init })
  vim.lsp.config("lua_ls", { settings = lua_lsp_settings })

  vim.lsp.enable "lua_ls"
end

local mason_path = vim.fn.stdpath "data" .. "/mason/packages/typescript-language-server"
local tsdk = mason_path .. "/node_modules/typescript/lib"

local servers = {
  html = {},
  cssls = {},
  clangd = {},
  bashls = {},
  lua_ls = {},
  nil_ls = {},
  dart_ls = {},

  rust_analyzer = {},
  kotlin_language_server = {},

  eslint_d = {},

  astro = {
    init_options = {
      typescript = {
        tsdk = tsdk,
      },
    },
  },

  ts_ls = {
    settings = {
      typescript = {
        format = {
          tabSize = 4,
          indentSize = 4,
          convertTabsToSpaces = true,
        },
      },
      javascript = {
        format = {
          tabSize = 4,
          indentSize = 4,
          convertTabsToSpaces = true,
        },
      },
    },
    init_options = {
      typescript = {
        tsdk = tsdk,
      },
    },
  },

  pyright = {
    settings = {
      python = {
        analysis = {
          autoSearchPaths = true,
          typeCheckingMode = "basic",
        },
      },
    },
  },
}

for name, opts in pairs(servers) do
  opts.on_attach = opts.on_attach or M.on_attach

  opts.capabilities = M.capabilities
  opts.on_init = M.on_init

  vim.lsp.config[name] = opts
  vim.lsp.enable(name)
end

return M
