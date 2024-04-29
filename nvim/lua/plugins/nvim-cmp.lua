return {
  "hrsh7th/nvim-cmp",
  event = "InsertEnter",
  dependencies = {
    "hrsh7th/cmp-buffer", -- source for text in buffer
    "hrsh7th/cmp-path",   -- source for file system paths
    "hrsh7th/cmp-calc",   -- source for file system paths
    "L3MON4D3/LuaSnip",   -- snippet engine
    {
      "Jezda1337/nvim-html-css",
      dependencies = {
        "nvim-treesitter/nvim-treesitter",
        "nvim-lua/plenary.nvim"
      },
      config = function()
        require("html-css"):setup()
      end
    },
    "amarakon/nvim-cmp-buffer-lines",
    "saadparwaiz1/cmp_luasnip",     -- for autocompletion
    "rafamadriz/friendly-snippets", -- useful snippets
  },
  config = function()
    local cmp = require("cmp")
    local luasnip = require("luasnip")
    local kind_icons = {
      Text = "󰊄",
      Method = "󰆦",
      Function = "󰊕",
      Constructor = "",
      Field = "󰇽",
      Variable = "󰂡",
      Class = "󰠱",
      Interface = "",
      Module = "󱊈",
      Property = "󰜢",
      Unit = "",
      Value = "󰎠",
      Enum = "",
      Keyword = "󰌋",
      Snippet = "󰅩",
      Color = "󰏘",
      File = "󰈙",
      Reference = "",
      Folder = "",
      EnumMember = "",
      Constant = "󰏿",
      Struct = "",
      Event = "",
      Operator = "󰆕",
      TypeParameter = "󰅲",
    }
    -- loads vscode style snippets from installed plugins (e.g. friendly-snippets)
    require("luasnip.loaders.from_vscode").lazy_load()
    cmp.setup.filetype({ "c", "cpp" }, {
      sources = {
        name = "buffer-lines",
        option = {
          leading_whitespace = false,
          max_indents = 0,
        }
      },
      formatting = {
        format = function(entry, vim_item)
          if entry.source.name == "buffer-lines" then
            vim_item.menu = ' 󱉥 '
          end
        end
      }
    })
    cmp.setup({
      completion = {
        completeopt = "menu,menuone,preview,noselect",
        -- completeopt = "menu,menuone,preview",
      },
      snippet = { -- configure how nvim-cmp interacts with snippet engine
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },
      mapping = cmp.mapping.preset.insert({
        ["<C-k>"] = cmp.mapping.select_prev_item(),   -- previous suggestion
        ["<C-j>"] = cmp.mapping.select_next_item(),   -- next suggestion
        ["<S-Tab>"] = cmp.mapping.select_prev_item(), -- previous suggestion
        ["<Tab>"] = cmp.mapping.select_next_item(),   -- next suggestion
        ["<C-b>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        ["<C-Space>"] = cmp.mapping.complete(), -- show completion suggestions
        ["<C-h>"] = cmp.mapping.abort(),        -- close completion window
        ["<C-e>"] = cmp.mapping.close(),        -- close completion window
        ["<C-l>"] = cmp.mapping({
          i = function(fallback)
            if cmp.visible() and cmp.get_active_entry() then
              cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = false })
            else
              fallback()
            end
          end,
          s = cmp.mapping.confirm({ select = true }),
          c = cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = true }),
        }),
      }),
      view = {
        entries = { name = 'custom' }
      },
      -- sources for autocompletion
      -- the order will affect the priority
      sources = cmp.config.sources({
        { name = "nvim_lsp" },
        { name = "luasnip" }, -- snippets
        { name = "buffer" },  -- text within current buffer
        { name = "path" },    -- file system paths
        { name = "calc" },    -- calculate
        {
          name = "html-css",
          option = {
            max_count = {}, -- not ready yet
            enable_on = {
              "html",
            },                                           -- set the file types you want the plugin to work on
            file_extensions = { "css", "sass", "less" }, -- set the local filetypes from which you want to derive classes
            style_sheets = {
              -- example of remote styles, only css no js for now
              -- "https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css",
              -- "https://cdn.jsdelivr.net/npm/bulma@0.9.4/css/bulma.min.css",
            }
          }
        },

      }),

      -- configure lspkind for vs-code like pictograms in completion menu
      formatting = {
        fields = { "menu", "abbr", "kind" },
        format = function(entry, vim_item)
          -- Kind icons
          vim_item.kind = string.format('%s', kind_icons[vim_item.kind]) -- This concatonates the icons with the name of the item kind
          -- vim_item.kind = string.format('%s %s', kind_icons[vim_item.kind], vim_item.kind) -- For more detailed cmp
          -- Source
          vim_item.menu = ({
            buffer = " 󱝴 ",
            nvim_lsp = " 󰗊 ",
            luasnip = " 󰬓 ",
            path = "  ",
            calc = " 󰃬 ",
            -- buffer = "<Buffer>",
            -- nvim_lsp = "<LSP>",
            -- luasnip = "<LuaSnip>",
            -- nvim_lua = "<Lua>",
            -- latex_symbols = "<LaTeX>",
          })[entry.source.name]
          if entry.source.name == "buffer-lines" then
            vim_item.menu = ' 󱉥 '
          end
          return vim_item
        end
      },
      window = {
        completion = {
          winhighlight = "Normal:Pmenu,FloatBorder:Pmenu,Search:None",
          side_padding = 0,
          -- scrollbar = false,
          max_width = 30,
          max_height = 100,
          border = 'single',
        },
        documentation = {
          winhighlight = "Normal:Pmenu,FloatBorder:Pmenu,Search:None",
          side_padding = 0,
          -- scrollbar = false,
          max_width = 30,
          max_height = 100,
          border = 'single',
        },
      },
    })
  end,
}
