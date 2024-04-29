return { -- Highlight, edit, and navigate code
  'nvim-treesitter/nvim-treesitter',
  dependencies = {
    {
      'HiPhish/nvim-ts-rainbow2',
      event = "VeryLazy",
      dependency = {
        'nvim-treesitter/nvim-treesitter',
      }
    },
    {
      "windwp/nvim-ts-autotag",
      dependency = {
        'nvim-treesitter/nvim-treesitter',
      }
    },
    {
      'nvim-treesitter/nvim-treesitter-refactor',
      dependency = {
        'nvim-treesitter/nvim-treesitter',
      }
    },
  },
  event = {
    'VeryLazy'
  },
  build = ":TSUpdate",
  config = function()
    local vim = vim
    local opt = vim.opt

    opt.foldmethod = "expr"
    opt.foldexpr = "nvim_treesitter#foldexpr()"

    require 'nvim-treesitter.configs'.setup {
      ensure_installed = { "lua", "vim", "vimdoc", "css", "scss", "html", "javascript", "python", "bash", "fish" },
      sync_install = true,
      auto_install = false,
      highlight = {
        enable = true,
      },
      indent = {
        enable = false,
      },
      rainbow = {
        enable = true,
        -- list of languages you want to disable the plugin for
        disable = { 'jsx', 'cpp' },
        -- Which query to use for finding delimiters
        query = 'rainbow-parens',
        -- Highlight the entire buffer all at once
        strategy = require('ts-rainbow').strategy.global,
      },
      autotag = {
        enable = true,
        enable_rename = true,
        enable_close = true,
        enable_close_on_slash = true,
        filetypes = { "html", "xml" },
      },
      refactor = {
        highlight_definitions = {
          enable = true,
          -- Set to false if you have an `updatetime` of ~100.
          clear_on_cursor_move = false,
        },
      },
    }
  end
}
